import { Terminal, IDisposable } from "@xterm/xterm";
import { FitAddon } from "@xterm/addon-fit";

export class Xterm {
    elem: HTMLElement;
    term: Terminal;
    resizeListener: () => void;

    message: HTMLElement;
    messageTimeout: number;
    messageTimer: number = 0;

    // Disposables for the input/resize listeners that WebTTY registers
    // (one of each at a time). Tracked so reconnects don't accumulate
    // duplicate subscribers, which would cause keystrokes to be sent
    // N times after N reconnects.
    private inputDisposable?: IDisposable;
    private remoteResizeDisposable?: IDisposable;

    constructor(elem: HTMLElement) {
        this.elem = elem;
        this.term = new Terminal();
        const fit = new FitAddon()
        this.term.loadAddon(fit);

        this.message = elem.ownerDocument.createElement("div");
        this.message.className = "xterm-overlay";
        this.messageTimeout = 2000;

        this.resizeListener = () => {
            fit.fit();
            this.term.scrollToBottom();
            this.showMessage(String(this.term.cols) + "x" + String(this.term.rows), this.messageTimeout);
        };

        window.addEventListener("resize", this.resizeListener);
        this.term.onResize(this.resizeListener)

        this.term.open(elem);
        fit.fit();
    };

    info(): { columns: number, rows: number } {
        return { columns: this.term.cols, rows: this.term.rows };
    };

    output(data: Uint8Array) {
        this.term.write(data);
    };

    showMessage(message: string, timeout: number) {
        this.message.textContent = message;
        this.elem.appendChild(this.message);

        if (this.messageTimer) {
            clearTimeout(this.messageTimer);
        }
        if (timeout > 0) {
            this.messageTimer = window.setTimeout(() => {
                this.elem.removeChild(this.message);
            }, timeout);
        }
    };

    removeMessage(): void {
        if (this.message.parentNode == this.elem) {
            this.elem.removeChild(this.message);
        }
    }

    setWindowTitle(title: string) {
        document.title = title;
    };

    onInput(callback: (input: string) => void) {
        this.inputDisposable?.dispose();
        this.inputDisposable = this.term.onData((data) => {
            callback(data);
        });
    };

    onResize(callback: (columns: number, rows: number) => void) {
        this.remoteResizeDisposable?.dispose();
        this.remoteResizeDisposable = this.term.onResize((data) => {
            callback(data.cols, data.rows);
        });
    };

    deactivate(): void {
        this.inputDisposable?.dispose();
        this.inputDisposable = undefined;
        this.remoteResizeDisposable?.dispose();
        this.remoteResizeDisposable = undefined;
        this.term.blur();
    }

    reset(): void {
        this.removeMessage();
        this.term.clear();
    }

    close(): void {
        window.removeEventListener("resize", this.resizeListener);
        this.inputDisposable?.dispose();
        this.remoteResizeDisposable?.dispose();
        this.term.dispose();
    }
}
