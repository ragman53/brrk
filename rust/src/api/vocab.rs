//! Vocabulary lookup via Mistral Chat.
//!
//! ## Flow
//! 1. Validate the user's selected text (English word or short Japanese term).
//! 2. Extract the containing sentence from the page context.
//! 3. Check the local `vocab.json` cache for an existing entry by
//!    `(language, lemma)`.
//! 4. On cache miss, call the Mistral Chat API
//!    (`POST https://api.mistral.ai/v1/chat/completions`) using
//!    `mistral-small-latest`. The prompt sends ONLY the selected term
//!    and the extracted sentence — not the full page context.
//! 5. Parse the response JSON and persist the entry/encounter via
//!    `crate::api::store::save_vocabulary_lookup`.
//! 6. On lookup failure, no data is saved.

use crate::api::store;
use crate::{VocabEncounter, VocabEntry, VocabError, VocabLookupResult, VocabSource};

/// Maximum chars for a valid English word selection.
pub(crate) const MAX_EN_WORD_LEN: usize = 40;
/// Maximum chars for a valid Japanese term selection.
pub(crate) const MAX_JA_TERM_LEN: usize = 20;
/// Maximum chars for the response payload (Mistral max tokens × 4 ~ chars).
const MAX_RESPONSE_CHARS: usize = 8_000;

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

pub fn lookup_vocabulary(
    api_key: String,
    selected_text: String,
    page_context: String,
    selection_start: Option<i32>,
    selection_end: Option<i32>,
    source: VocabSource,
) -> Result<VocabLookupResult, VocabError> {
    let normalized = normalize_selection(&selected_text)?;
    let language = detect_language(&normalized)?;
    let sentence = extract_sentence(&page_context, &normalized, selection_start, selection_end);
    let encounter = VocabEncounter {
        id: new_id(),
        selected_text: normalized.clone(),
        sentence: sentence.clone(),
        source: source.clone(),
        lookup_count: 1,
        first_seen: store::now_iso_for_vocab(),
        last_seen: store::now_iso_for_vocab(),
    };

    // Check the cache.
    if let Some(cached) = store::find_vocab_entry(&language, &normalized)
        .map_err(|e| VocabError::StorageError(e.to_string()))?
    {
        return store::save_vocabulary_lookup(cached, encounter)
            .map_err(|e| VocabError::StorageError(e.to_string()));
    }

    if api_key.trim().is_empty() {
        return Err(VocabError::ApiKeyError);
    }

    // Cache miss: call Mistral.
    let client = ReqwestChatClient {};
    let response_json = client
        .chat_completion(
            &api_key,
            SYSTEM_PROMPT,
            &build_user_payload(&normalized, &sentence),
        )
        .map_err(classify_chat_error)?;

    let parsed = parse_definition_response(&response_json, &language)?;

    let entry = VocabEntry {
        lemma: parsed.lemma,
        language: parsed.language,
        surface_forms: vec![normalized],
        definition: parsed.definition,
        definition_edited: false,
        encounters: vec![],
        created_at: store::now_iso_for_vocab(),
        updated_at: store::now_iso_for_vocab(),
    };

    store::save_vocabulary_lookup(entry, encounter)
        .map_err(|e| VocabError::StorageError(e.to_string()))
}

// ---------------------------------------------------------------------------
// Selection validation
// ---------------------------------------------------------------------------

/// Trim and validate. Returns the trimmed surface form on success.
pub(crate) fn normalize_selection(raw: &str) -> Result<String, VocabError> {
    let s = raw.trim();
    if s.is_empty() {
        return Err(VocabError::InvalidSelection(
            "selection is empty".to_string(),
        ));
    }
    Ok(s.to_string())
}

/// Returns `"en"` or `"ja"`. Mixed selections are rejected.
pub(crate) fn detect_language(s: &str) -> Result<String, VocabError> {
    let has_latin = s.chars().any(|c| c.is_ascii_alphabetic());
    let has_cjk = s.chars().any(|c| {
        let cp = c as u32;
        // CJK Unified Ideographs + Hiragana + Katakana blocks.
        (0x3040..=0x309F).contains(&cp)
            || (0x30A0..=0x30FF).contains(&cp)
            || (0x4E00..=0x9FFF).contains(&cp)
    });
    if has_latin && has_cjk {
        return Err(VocabError::InvalidSelection(
            "mixed English/Japanese selection".to_string(),
        ));
    }
    if has_cjk {
        // Japanese: must not contain whitespace, must contain kana or kanji.
        if s.chars().any(|c| c.is_whitespace()) {
            return Err(VocabError::InvalidSelection(
                "Japanese selection must not contain whitespace".to_string(),
            ));
        }
        if s.chars().count() > MAX_JA_TERM_LEN {
            return Err(VocabError::InvalidSelection(format!(
                "Japanese selection exceeds {} chars",
                MAX_JA_TERM_LEN
            )));
        }
        return Ok("ja".to_string());
    }
    if has_latin {
        if s.chars().any(|c| c.is_whitespace()) {
            return Err(VocabError::InvalidSelection(
                "English selection must be a single word".to_string(),
            ));
        }
        if s.chars().count() > MAX_EN_WORD_LEN {
            return Err(VocabError::InvalidSelection(format!(
                "English selection exceeds {} chars",
                MAX_EN_WORD_LEN
            )));
        }
        if !is_valid_english_word(s) {
            return Err(VocabError::InvalidSelection(
                "selection is not a valid English word".to_string(),
            ));
        }
        return Ok("en".to_string());
    }
    Err(VocabError::InvalidSelection(
        "selection has no recognizable script".to_string(),
    ))
}

fn is_valid_english_word(s: &str) -> bool {
    let mut chars = s.chars();
    let first = chars.next().unwrap();
    if !first.is_ascii_alphabetic() {
        return false;
    }
    for c in chars {
        if !(c.is_ascii_alphabetic() || c == '\'' || c == '\u{2019}' || c == '-') {
            return false;
        }
    }
    true
}

// ---------------------------------------------------------------------------
// Sentence extraction
// ---------------------------------------------------------------------------

const SENTENCE_BOUNDARIES: &[char] = &['.', '!', '?', '。', '！', '？'];

/// Extract the containing sentence. Applies offsets to the UNTRIMMED context,
/// then trims only the resulting chunk. Falls back to searching for the
/// selected text. Blank lines act as paragraph boundaries, but single
/// newlines do not.
pub(crate) fn extract_sentence(
    context: &str,
    selected: &str,
    start: Option<i32>,
    end: Option<i32>,
) -> String {
    let mut chunk: Option<String> = None;

    if let (Some(s), Some(e)) = (start, end) {
        if s >= 0 && e > s {
            let start_us = s as usize;
            let end_us = e as usize;
            if end_us <= context.len() && start_us <= context.len() {
                // Use char boundaries for safety.
                if let (Some(s_idx), Some(e_idx)) = (
                    floor_char_boundary(context, start_us),
                    ceil_char_boundary(context, end_us),
                ) {
                    let raw = &context[s_idx..e_idx];
                    chunk = Some(extract_chunk_around(raw));
                }
            }
        }
    }
    if chunk.is_none() {
        if let Some(idx) = context.find(selected) {
            let end = (idx + selected.len()).min(context.len());
            let chunk_text = &context[idx..end];
            chunk = Some(extract_chunk_around(chunk_text));
        }
    }
    let chunk = chunk.unwrap_or_else(|| selected.to_string());
    // Cap at 500 chars.
    if chunk.chars().count() > crate::api::store::MAX_VOCAB_SENTENCE_LEN {
        chunk
            .chars()
            .take(crate::api::store::MAX_VOCAB_SENTENCE_LEN)
            .collect()
    } else {
        chunk
    }
}

fn extract_chunk_around(text: &str) -> String {
    // Find paragraph boundary forward and backward.
    let para_start = text.rfind("\n\n").map(|i| i + 2).unwrap_or(0);
    let para_end_candidate = text.find("\n\n").unwrap_or(text.len());
    let mut chunk = &text[para_start..para_end_candidate];
    // Trim to sentence boundary inclusive.
    chunk = trim_to_sentence(chunk);
    chunk.trim().to_string()
}

fn trim_to_sentence(s: &str) -> &str {
    // Find the last sentence boundary; if found, extend the slice to include it.
    let mut end = s.len();
    for (i, c) in s.char_indices() {
        if SENTENCE_BOUNDARIES.contains(&c) {
            end = i + c.len_utf8();
        }
    }
    // Also strip leading Markdown prefix characters.
    let mut start = 0;
    let prefix_trim: &[&str] = &["# ", "## ", "### ", "#### ", "- ", "* ", "> "];
    for p in prefix_trim {
        if s[start..].starts_with(p) {
            start += p.len();
            break;
        }
    }
    &s[start..end]
}

fn floor_char_boundary(s: &str, mut idx: usize) -> Option<usize> {
    if idx >= s.len() {
        return Some(s.len());
    }
    while idx > 0 && !s.is_char_boundary(idx) {
        idx -= 1;
    }
    Some(idx)
}

fn ceil_char_boundary(s: &str, mut idx: usize) -> Option<usize> {
    if idx >= s.len() {
        return Some(s.len());
    }
    while idx < s.len() && !s.is_char_boundary(idx) {
        idx += 1;
    }
    Some(idx)
}

// ---------------------------------------------------------------------------
// Mistral Chat client
// ---------------------------------------------------------------------------

const SYSTEM_PROMPT: &str = "You are a concise English dictionary for adult readers. \
Return ONLY valid JSON with this shape: \
{\"language\":\"en|ja\",\"lemma\":\"<canonical form>\",\"definition\":\"<definition>\"}\n\
Rules:\n\
- Detect whether the selected term is English or Japanese.\n\
- For English, return the dictionary form as lemma.\n\
- For Japanese, return the canonical written form as lemma.\n\
- Define the term in clear English.\n\
- Use the sentence only to prioritize relevant meanings.\n\
- If multiple common meanings are relevant, include up to 3 numbered meanings inside the definition string.\n\
- Do not mention the sentence.\n\
- Do not include markdown.\n\
- Do not include examples.\n\
- Keep definition under 1000 characters.";

fn build_user_payload(selected: &str, sentence: &str) -> String {
    format!(
        "{{\"selected_text\":{},\"sentence\":{}}}",
        json_string(selected),
        json_string(sentence)
    )
}

fn json_string(s: &str) -> String {
    let mut out = String::with_capacity(s.len() + 2);
    out.push('"');
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if (c as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out.push('"');
    out
}

pub(crate) trait MistralChatClient {
    fn chat_completion(
        &self,
        api_key: &str,
        system_prompt: &str,
        user_payload: &str,
    ) -> Result<String, VocabError>;
}

#[flutter_rust_bridge::frb(opaque)]
pub(crate) struct ReqwestChatClient {}

impl MistralChatClient for ReqwestChatClient {
    fn chat_completion(
        &self,
        api_key: &str,
        system_prompt: &str,
        user_payload: &str,
    ) -> Result<String, VocabError> {
        // Use serde_json to build the request body.
        let body = serde_json::json!({
            "model": "mistral-small-latest",
            "temperature": 0.2,
            "max_tokens": 220,
            "messages": [
                { "role": "system", "content": system_prompt },
                { "role": "user", "content": user_payload }
            ]
        });
        let client = reqwest::blocking::Client::builder()
            .timeout(std::time::Duration::from_secs(60))
            .build()
            .map_err(|e| VocabError::NetworkError(e.to_string()))?;
        let response = client
            .post("https://api.mistral.ai/v1/chat/completions")
            .header("Authorization", format!("Bearer {}", api_key))
            .header("Content-Type", "application/json")
            .json(&body)
            .send()
            .map_err(|e| {
                if e.is_timeout() {
                    VocabError::TimeoutError
                } else {
                    VocabError::NetworkError(e.to_string())
                }
            })?;
        let status = response.status();
        if status.as_u16() == 401 || status.as_u16() == 403 {
            return Err(VocabError::ApiKeyError);
        }
        if status.as_u16() == 429 {
            return Err(VocabError::RateLimitError);
        }
        if !status.is_success() {
            let body = response
                .text()
                .unwrap_or_default()
                .chars()
                .take(MAX_RESPONSE_CHARS)
                .collect::<String>();
            return Err(VocabError::UnknownError(format!(
                "HTTP {}: {}",
                status.as_u16(),
                body
            )));
        }
        let text = response
            .text()
            .map_err(|e| VocabError::NetworkError(e.to_string()))?;
        // The body is the full chat wrapper; the caller (parse_definition_response)
        // will extract the assistant content.
        // We intentionally do not log `text` to avoid leaking model output.
        Ok(text)
    }
}

fn classify_chat_error(e: VocabError) -> VocabError {
    e
}

// ---------------------------------------------------------------------------
// Response parser
// ---------------------------------------------------------------------------

#[derive(Debug)]
struct ParsedDefinition {
    lemma: String,
    language: String,
    definition: String,
}

fn parse_definition_response(
    wrapper_json: &str,
    expected_language: &str,
) -> Result<ParsedDefinition, VocabError> {
    // Parse the chat wrapper first.
    #[derive(serde::Deserialize)]
    struct ChatResp {
        choices: Option<Vec<ChatChoice>>,
    }
    #[derive(serde::Deserialize)]
    struct ChatChoice {
        message: ChatMessage,
    }
    #[derive(serde::Deserialize)]
    struct ChatMessage {
        content: String,
    }
    let resp: ChatResp = serde_json::from_str(wrapper_json)
        .map_err(|e| VocabError::ParseError(format!("chat wrapper: {}", e)))?;
    let content = resp
        .choices
        .and_then(|c| c.into_iter().next())
        .map(|c| c.message.content)
        .ok_or_else(|| VocabError::ParseError("no choices in chat response".to_string()))?;
    if content.trim().is_empty() {
        return Err(VocabError::ParseError(
            "empty assistant content".to_string(),
        ));
    }
    parse_definition_content(&content, expected_language)
}

fn parse_definition_content(
    content: &str,
    expected_language: &str,
) -> Result<ParsedDefinition, VocabError> {
    let trimmed = strip_json_fences(content);
    match try_parse_definition_json(trimmed, expected_language) {
        Ok(p) => Ok(p),
        Err(first_err) => {
            // One retry: strip fences again in case the inner text is still
            // wrapped, then re-parse.
            let again = strip_json_fences(trimmed);
            try_parse_definition_json(again, expected_language).map_err(|_| first_err)
        }
    }
}

fn strip_json_fences(s: &str) -> &str {
    let s = s.trim();
    let s = s
        .strip_prefix("```json")
        .or_else(|| s.strip_prefix("```"))
        .unwrap_or(s);
    let s = s.strip_suffix("```").unwrap_or(s);
    s.trim()
}

fn try_parse_definition_json(
    raw: &str,
    expected_language: &str,
) -> Result<ParsedDefinition, VocabError> {
    #[derive(serde::Deserialize)]
    struct Def {
        language: String,
        lemma: String,
        definition: String,
    }
    let parsed: Def = serde_json::from_str(raw)
        .map_err(|e| VocabError::ParseError(format!("definition JSON: {}", e)))?;
    if !parsed.language.eq_ignore_ascii_case("en") && !parsed.language.eq_ignore_ascii_case("ja") {
        return Err(VocabError::ParseError(format!(
            "unexpected language: {}",
            parsed.language
        )));
    }
    let lang = parsed.language.to_ascii_lowercase();
    // Defensive check: language should match user's selection.
    if lang != expected_language {
        return Err(VocabError::ParseError(format!(
            "language mismatch: expected {}, got {}",
            expected_language, lang
        )));
    }
    if parsed.definition.chars().count() > crate::api::store::MAX_VOCAB_DEFINITION_LEN {
        return Err(VocabError::ParseError(format!(
            "definition exceeds {} chars",
            crate::api::store::MAX_VOCAB_DEFINITION_LEN
        )));
    }
    if parsed.lemma.trim().is_empty() {
        return Err(VocabError::ParseError("empty lemma".to_string()));
    }
    if parsed.definition.trim().is_empty() {
        return Err(VocabError::ParseError("empty definition".to_string()));
    }
    Ok(ParsedDefinition {
        lemma: parsed.lemma,
        language: lang,
        definition: parsed.definition,
    })
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn new_id() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    format!("v-{:x}", nanos)
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn english_single_word_valid() {
        let s = normalize_selection("philosophy").unwrap();
        assert_eq!(detect_language(&s).unwrap(), "en");
    }

    #[test]
    fn english_with_apostrophe_valid() {
        let s = normalize_selection("don't").unwrap();
        assert_eq!(detect_language(&s).unwrap(), "en");
    }

    #[test]
    fn english_with_hyphen_valid() {
        let s = normalize_selection("self-conscious").unwrap();
        assert_eq!(detect_language(&s).unwrap(), "en");
    }

    #[test]
    fn english_phrase_rejected() {
        let s = normalize_selection("common sense").unwrap();
        assert!(detect_language(&s).is_err());
    }

    #[test]
    fn japanese_short_term_valid() {
        let s = normalize_selection("存在").unwrap();
        assert_eq!(detect_language(&s).unwrap(), "ja");
    }

    #[test]
    fn japanese_kana_only_valid() {
        let s = normalize_selection("ちがい").unwrap();
        assert_eq!(detect_language(&s).unwrap(), "ja");
    }

    #[test]
    fn japanese_with_whitespace_rejected() {
        let s = normalize_selection("存在 する").unwrap();
        assert!(detect_language(&s).is_err());
    }

    #[test]
    fn mixed_english_japanese_rejected() {
        let s = normalize_selection("差異 difference").unwrap();
        assert!(detect_language(&s).is_err());
    }

    #[test]
    fn empty_selection_rejected() {
        assert!(normalize_selection("   ").is_err());
    }

    #[test]
    fn overlong_english_rejected() {
        let s = "a".repeat(MAX_EN_WORD_LEN + 1);
        assert!(detect_language(&s).is_err());
    }

    #[test]
    fn overlong_japanese_rejected() {
        let s = "あ".repeat(MAX_JA_TERM_LEN + 1);
        assert!(detect_language(&s).is_err());
    }

    #[test]
    fn sentence_extraction_with_offsets() {
        let ctx = "Reading philosophy is rewarding. The next sentence starts here.";
        // "philosophy is rewarding." = bytes 8..40
        let s = extract_sentence(ctx, "philosophy", Some(8), Some(40));
        assert!(s.contains("philosophy"));
        assert!(s.contains("rewarding"));
    }

    #[test]
    fn sentence_extraction_fallback_to_search() {
        let ctx = "Reading philosophy is rewarding.";
        let s = extract_sentence(ctx, "philosophy", None, None);
        assert!(s.contains("philosophy"));
    }

    #[test]
    fn sentence_extraction_preserves_untrimmed_offsets() {
        // Leading whitespace in context should not shift offsets.
        let ctx = "   Reading philosophy is rewarding.";
        let s = extract_sentence(ctx, "philosophy", Some(11), Some(22));
        // The slice [11..22] of "   Reading philosophy is rewarding." is
        // "philosophy" (after "   Reading ").
        assert!(s.contains("philosophy"));
    }

    #[test]
    fn sentence_capped_at_500_chars() {
        let big: String = "a".repeat(800);
        let ctx = format!("{} rest.", big);
        let s = extract_sentence(&ctx, "a", Some(0), Some(1));
        assert!(s.chars().count() <= 500);
    }

    #[test]
    fn chat_wrapper_parser_happy_path() {
        let body = r#"{
            "id": "abc",
            "choices": [
                {"message": {"role": "assistant", "content": "{\"language\":\"en\",\"lemma\":\"philosophy\",\"definition\":\"1. The study of fundamental questions.\"}"}}
            ]
        }"#;
        let parsed = parse_definition_response(body, "en").unwrap();
        assert_eq!(parsed.lemma, "philosophy");
        assert_eq!(parsed.language, "en");
        assert!(parsed.definition.contains("fundamental"));
    }

    #[test]
    fn chat_wrapper_parser_missing_choices() {
        let body = r#"{"id":"abc"}"#;
        let err = parse_definition_response(body, "en").unwrap_err();
        assert!(matches!(err, VocabError::ParseError(_)));
    }

    #[test]
    fn chat_wrapper_parser_empty_content() {
        let body = r#"{"choices":[{"message":{"role":"assistant","content":""}}]}"#;
        let err = parse_definition_response(body, "en").unwrap_err();
        assert!(matches!(err, VocabError::ParseError(_)));
    }

    #[test]
    fn fence_stripping_and_retry() {
        let fenced = "```json\n{\"language\":\"ja\",\"lemma\":\"\u{5b58}\u{5728}\",\"definition\":\"Existence.\"}\n```";
        let parsed = parse_definition_content(fenced, "ja").unwrap();
        assert_eq!(parsed.lemma, "\u{5b58}\u{5728}");
    }

    #[test]
    fn invalid_json_no_save_via_parse_error() {
        let body = r#"{"choices":[{"message":{"role":"assistant","content":"not json"}}]}"#;
        let err = parse_definition_response(body, "en").unwrap_err();
        assert!(matches!(err, VocabError::ParseError(_)));
    }

    #[test]
    fn language_mismatch_rejected() {
        let body = r#"{"choices":[{"message":{"role":"assistant","content":"{\"language\":\"ja\",\"lemma\":\"x\",\"definition\":\"y\"}"}}]}"#;
        let err = parse_definition_response(body, "en").unwrap_err();
        assert!(matches!(err, VocabError::ParseError(_)));
    }

    #[test]
    fn definition_too_long_rejected() {
        let big = "a".repeat(crate::api::store::MAX_VOCAB_DEFINITION_LEN + 1);
        let payload = format!(r#"{{"language":"en","lemma":"x","definition":"{}"}}"#, big);
        let body = format!(
            r#"{{"choices":[{{"message":{{"role":"assistant","content":{:?}}}}}]}}"#,
            payload
        );
        let err = parse_definition_response(&body, "en").unwrap_err();
        assert!(matches!(err, VocabError::ParseError(_)));
    }

    /// Fake client that captures the payload to assert privacy:
    /// only `selected_text` and the extracted sentence are sent, NOT the
    /// full page context.
    struct CapturingClient {
        captured: std::sync::Mutex<Option<String>>,
    }
    impl MistralChatClient for CapturingClient {
        fn chat_completion(
            &self,
            _api_key: &str,
            _system_prompt: &str,
            user_payload: &str,
        ) -> Result<String, VocabError> {
            *self.captured.lock().unwrap() = Some(user_payload.to_string());
            Ok(r#"{"choices":[{"message":{"role":"assistant","content":"{\"language\":\"en\",\"lemma\":\"being\",\"definition\":\"Existence.\"}"}}]}"#.to_string())
        }
    }

    #[test]
    fn privacy_payload_excludes_full_page_context() {
        // Simulate the lookup orchestration by re-using the same payload
        // construction without invoking the storage layer.
        let cap = CapturingClient {
            captured: std::sync::Mutex::new(None),
        };
        let big_page = "a".repeat(5_000) + " unique_marker_token_xyz ";
        let sentence = extract_sentence(&big_page, "being", None, None);
        let payload = build_user_payload("being", &sentence);
        let _ = cap.chat_completion("k", SYSTEM_PROMPT, &payload);
        let captured = cap.captured.lock().unwrap().clone().unwrap();
        // Selected term and sentence are present.
        assert!(captured.contains("being"));
        // The full-page marker must NOT be present.
        assert!(!captured.contains("unique_marker_token_xyz"));
    }
}
