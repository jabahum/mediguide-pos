import { useEffect, useRef, useState, type FormEvent } from "react";

import {
  askPublicGuideline,
  PublicApiError,
  type PublicAICitation,
  type PublicGuideline,
} from "../../../api/public-guidelines";
import { SecureMarkdown } from "./SecureMarkdown";

type AssistantMessage = {
  id: string;
  role: "user" | "assistant";
  content: string;
  citations?: PublicAICitation[];
};

type GuidelineAssistantProps = {
  guideline: PublicGuideline;
  open: boolean;
  onClose: () => void;
  onCitation: (citation: PublicAICitation) => void;
};

const suggestions = [
  "What are the key recommendations?",
  "What warning signs require referral?",
  "Summarize the treatment guidance.",
];

export function GuidelineAssistant({ guideline, open, onClose, onCitation }: GuidelineAssistantProps) {
  const [messages, setMessages] = useState<AssistantMessage[]>([]);
  const [question, setQuestion] = useState("");
  const [pending, setPending] = useState(false);
  const [error, setError] = useState("");
  const abortRef = useRef<AbortController | null>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const endRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (open) window.setTimeout(() => inputRef.current?.focus(), 0);
  }, [open]);
  useEffect(() => {
    if (!open) {
      abortRef.current?.abort();
      return;
    }
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };
    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
      document.body.style.overflow = previousOverflow;
    };
  }, [onClose, open]);
  useEffect(() => endRef.current?.scrollIntoView({ block: "end" }), [messages, pending]);
  useEffect(() => () => abortRef.current?.abort(), []);
  if (!open) return null;

  const ask = async (value: string) => {
    const normalized = value.trim();
    if (normalized.length < 2 || pending) return;
    const userMessage: AssistantMessage = { id: crypto.randomUUID(), role: "user", content: normalized };
    setMessages((current) => [...current, userMessage]);
    setQuestion("");
    setError("");
    setPending(true);
    const controller = new AbortController();
    abortRef.current = controller;
    try {
      const response = await askPublicGuideline(guideline.id, normalized, controller.signal);
      setMessages((current) => [...current, { id: crypto.randomUUID(), role: "assistant", content: response.answer, citations: response.citations }]);
    } catch (caught) {
      if (controller.signal.aborted) return;
      if (caught instanceof PublicApiError && caught.kind === "rate-limited") {
        setError(`The assistant request limit has been reached. Try again${caught.retryAfterSeconds ? ` in ${caught.retryAfterSeconds} seconds` : " shortly"}.`);
      } else {
        setError("The guideline assistant is temporarily unavailable. The published guideline remains available to read and search.");
      }
    } finally {
      if (abortRef.current === controller) abortRef.current = null;
      setPending(false);
    }
  };

  const submit = (event: FormEvent) => { event.preventDefault(); void ask(question); };

  return <>
    <button className="assistant-scrim" type="button" aria-label="Close guideline assistant" onClick={onClose} />
    <aside className="guideline-assistant" role="dialog" aria-modal="true" aria-labelledby="guideline-assistant-title">
      <header><div><span>AI guideline assistant</span><h2 id="guideline-assistant-title">Ask about this guideline</h2></div><button type="button" aria-label="Close guideline assistant" onClick={onClose}>×</button></header>
      <div className="assistant-safety" role="note">Answers use approved content from <strong>{guideline.title}</strong>. Verify citations and use clinical judgement.</div>
      <div className="assistant-messages" aria-live="polite">
        {!messages.length && <div className="assistant-welcome"><div className="assistant-mark" aria-hidden="true">✦</div><h3>How can I help?</h3><p>Ask for a summary, recommendation, warning sign, treatment, or referral criterion from this publication.</p><div>{suggestions.map((suggestion) => <button type="button" key={suggestion} onClick={() => void ask(suggestion)}>{suggestion}</button>)}</div></div>}
        {messages.map((message) => <article className={`assistant-message is-${message.role}`} key={message.id}>
          <strong>{message.role === "user" ? "You" : "MediGuide AI"}</strong>
          {message.role === "assistant" ? <div className="assistant-answer markdown-content"><SecureMarkdown content={message.content} /></div> : <p>{message.content}</p>}
          {message.citations?.length ? <div className="assistant-citations"><span>Sources</span>{message.citations.map((citation, index) => <button type="button" key={`${citation.chunk_id}-${index}`} onClick={() => onCitation(citation)}><b>{index + 1}</b><span>{citation.title || "Guideline section"}<small>{citation.source_name}{citation.page_start ? ` · Page ${citation.page_start}${citation.page_end && citation.page_end !== citation.page_start ? `–${citation.page_end}` : ""}` : ""}</small></span></button>)}</div> : null}
        </article>)}
        {pending && <div className="assistant-thinking"><i /><i /><i /><span className="visually-hidden">Searching approved guideline content</span></div>}
        {error && <div className="assistant-error" role="alert">{error}</div>}
        <div ref={endRef} />
      </div>
      <form className="assistant-composer" onSubmit={submit}><textarea ref={inputRef} rows={2} maxLength={1200} value={question} placeholder="Ask a clinical question…" aria-label="Question about this guideline" onChange={(event) => setQuestion(event.target.value)} onKeyDown={(event) => { if (event.key === "Enter" && !event.shiftKey) { event.preventDefault(); event.currentTarget.form?.requestSubmit(); } }} /><button type="submit" disabled={pending || question.trim().length < 2} aria-label="Ask question">↑</button><small>AI can make mistakes. Verify cited guidance before clinical use.</small></form>
    </aside>
  </>;
}
