import {
  Button,
  Dialog,
  DialogTrigger,
  Modal,
  ModalOverlay,
} from "react-aria-components/Modal";

export const navigationDrawerImpl = (classes) => (triggerIcon) => (closeIcon) => (content) => (
  <DialogTrigger>
    <Button aria-label="Open navigation" className={classes.trigger} type="button">
      {triggerIcon}
    </Button>
    <ModalOverlay
      className={({ isEntering, isExiting }) => classes.overlay(isEntering || isExiting)}
      isDismissable
    >
      <Modal className={({ isEntering, isExiting }) => classes.modal(isEntering || isExiting)}>
        <Dialog
          aria-label="Navigation"
          className={classes.dialog}
          data-navigation-drawer
        >
          <div className={classes.closeRow}>
            <Button aria-label="Close navigation" className={classes.close} slot="close" type="button">
              {closeIcon}
            </Button>
          </div>
          {content}
        </Dialog>
      </Modal>
    </ModalOverlay>
  </DialogTrigger>
);
