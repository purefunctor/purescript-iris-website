import { useState } from "react";
import { Button } from "react-aria-components/Button";
import { Tooltip, TooltipTrigger } from "react-aria-components/Tooltip";
import InfoIcon from "~icons/lucide/info";

export function infoButtonImpl({ className, text, tooltipClassName }) {
  const [open, setOpen] = useState(false);

  return (
    <TooltipTrigger delay={300} isOpen={open} onOpenChange={setOpen}>
      <Button aria-label={text} className={className} onPress={() => setOpen(true)}>
        <InfoIcon aria-hidden="true" focusable="false" />
      </Button>
      <Tooltip className={tooltipClassName} offset={8} placement="top end">{text}</Tooltip>
    </TooltipTrigger>
  );
}
