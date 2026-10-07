import { useEffect, useState } from "react";
import { Button, Tooltip, TooltipTrigger } from "react-aria-components";
import CheckIcon from "~icons/lucide/check";
import CopyIcon from "~icons/lucide/copy";

async function copyToClipboard(text, fallbackClassName) {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.readOnly = true;
    textarea.className = fallbackClassName;
    document.body.append(textarea);
    textarea.select();
    const copied = document.execCommand("copy");
    textarea.remove();
    return copied;
  }
}

export function copyButtonImpl({ className, copiedClassName, fallbackClassName, label, text, tooltipClassName }) {
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!copied) return undefined;
    const timeout = window.setTimeout(() => setCopied(false), 1400);
    return () => window.clearTimeout(timeout);
  }, [copied]);

  const copy = async () => {
    if (await copyToClipboard(text, fallbackClassName)) setCopied(true);
  };

  return (
    <TooltipTrigger isOpen={copied}>
      <Button
        aria-label={label}
        className={copied ? copiedClassName : className}
        onBlur={() => setCopied(false)}
        onPress={copy}
      >
        {copied ? <CheckIcon aria-hidden="true" focusable="false" /> : <CopyIcon aria-hidden="true" focusable="false" />}
      </Button>
      <Tooltip className={tooltipClassName} offset={8} placement="top">Copied</Tooltip>
    </TooltipTrigger>
  );
}
