import { createPortal } from "react-dom";

export { default as chevronRightIcon } from "~icons/lucide/chevron-right";
export { default as filePlusIcon } from "~icons/lucide/file-plus";
export { default as pencilIcon } from "~icons/lucide/pencil";
export { default as trashIcon } from "~icons/lucide/trash-2";
export { default as fileIcon } from "~icons/material-icon-theme/document";
export { default as javaScriptIcon } from "~icons/material-icon-theme/javascript";
export { default as pureScriptIcon } from "~icons/material-icon-theme/purescript";
export { default as reactIcon } from "~icons/material-icon-theme/react";

export const portalToBody = (children) => createPortal(children, document.body);
