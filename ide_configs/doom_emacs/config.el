;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Deepesh Padala"
      user-mail-address "ds3a@protonmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-ayu-mirage)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-agenda-files '("~/Documents/org/scripting_notes.org" "~/Documents/org/todo.org"))
(setq org-directory "~/Documents/org/")

(after! lsp-rust
  (setq lsp-rust-server 'rust-analyzer))


(after! doom
  (smartparens-mode -1)
  (smartparens-global-mode -1)
)
;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; custom keybindings and functions
(defhydra doom-window-resize-hydra (:hint nil)
  "
             _k_ increase height
_h_ decrease width    _l_ increase width
             _j_ decrease height
"
  ("h" evil-window-decrease-width)
  ("j" evil-window-increase-height)
  ("k" evil-window-decrease-height)
  ("l" evil-window-increase-width)

  ("q" nil))

(map!
    (:prefix "SPC w"
      :desc "Hydra resize" :n "z" #'doom-window-resize-hydra/body))



;; clipboard2org
;;; Code:
(defun clipboard2org-paste()
  "Paste HTML as org by using pandoc, or insert an image from the clipboard.
It inserts the image by first saving it with the unixtime name in a ./img/ sub-directory"
  (interactive)
  (let* ((data-file (gui-backend-get-selection 'CLIPBOARD 'text/uri-list))
         (data-html (or (gui-backend-get-selection 'PRIMARY 'text/html) (gui-backend-get-selection 'CLIPBOARD 'text/html)))
         (data-png (or (gui-backend-get-selection 'PRIMARY 'image/png) (gui-backend-get-selection 'CLIPBOARD 'image/png)))
         (data-jpg (or (gui-backend-get-selection 'PRIMARY 'image/jpeg) (gui-backend-get-selection 'CLIPBOARD 'image/jpeg)))
         (text-raw (gui-get-selection)))
    (cond
     (data-file (clipboard2org--file data-file))
     (data-jpg (clipboard2org--image data-jpg ".jpg"))
     (data-png (clipboard2org--image data-png ".png"))
     (data-html (clipboard2org--html data-html))
     (text-raw (yank)))))


(map!
    (:prefix "SPC i"
      :desc "Paste image from clipboard" :n "i" #'clipboard2org-paste))

(defun clipboard2org--file(file-url)
  "Inserts a list of files. Useful if you copied files from your file explorer
and want to insert links to them into your org file"
  (let* ((decoded-file-url (decode-coding-string file-url 'raw-text t nil))
         (decoded-file-url (substring decoded-file-url 0 -1))
         (file-list (split-string decoded-file-url)))
    (dolist (file-url file-list)
      (let* ((file-url (replace-regexp-in-string "%20" " " file-url))
            (file-name (file-name-nondirectory file-url)))
      (insert (concat "[["file-url"]["file-name "]]\n"))))))

(defun clipboard2org--html(html-data)
  "Insert html data into the buffer.
HTML-DATA: html data from the clipboard"
  (let* ((decoded-html (decode-coding-string html-data 'unix))
         (text-html (shell-command-to-string (concat "echo "  (shell-quote-argument decoded-html) "|timeout 2  pandoc --wrap=preserve -f html-native_divs-native_spans -t org"))))
    (insert text-html)))


(defun clipboard2org--image(image-data extension)
  "Insert image into the buffer.
IMAGE-DATA: Raw image-data from the clipboard
EXTENSION: the image extensions, for example png, jpg. Additional support for others is trivial."
  (let* ((image-directory "./img/")
         (temp-file-name
          (let ((coding-system-for-write 'raw-text)
                (buffer-file-coding-system 'raw-text))
            (make-directory image-directory t)
            (make-temp-file "img" nil extension image-data)))
         (file-name (replace-regexp-in-string "\\." "" (format "%s" (float-time))))
         (new-name (concat image-directory  file-name  extension)))
    (rename-file temp-file-name  new-name)
    (insert "#+ATTR_ORG: :width 300\n")
    (insert (concat  "#+CAPTION: "  "\n"))
    (insert (concat "[[file:" new-name "][file:" new-name "]]"))
    (org-display-inline-images)))

(provide 'clipboard2org)
;;; clipboard2org.el ends here
Footer
