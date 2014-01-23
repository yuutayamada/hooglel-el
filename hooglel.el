;;; hooglel.el --- hoogle local server front end

;; Copyright (C) 2014 by Yuta Yamada

;; Author: Yuta Yamada <cokesboy"at"gmail.com>
;; URL: https://github.com/yuutayamada/hooglel-el
;; Version: 0.0.1
;; Package-Requires: ((package "version-number"))
;; Keywords: keyword

;;; License:
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;; Commentary:

;;; Code:
(eval-when-compile (require 'cl))
(require 'thingatpt)

(defvar hooglel-server-process-name "emacs-local-hoogle")
(defvar hooglel-server-buffer-name (format "*%s*" hooglel-server-process-name))
(defvar hooglel-port-number 49513 "Port number.")

(defun hooglel-start-server ()
  "Start hooglel local server."
  (interactive)
  (unless (hooglel-server-live-p)
    (start-process
     hooglel-server-process-name
     (get-buffer-create hooglel-server-buffer-name) "/bin/sh" "-c"
     (format "hoogle server -p %i" hooglel-port-number))
    (add-hook 'kill-emacs-hook 'hooglel-kill-server)))

(defun hooglel-server-live-p ()
  "Whether hoogle server is live or not."
  (condition-case err
      (process-live-p (get-buffer-create hooglel-server-buffer-name))
    (error nil)))

(defun hooglel-kill-server ()
  "Kill hoogle server if it is live."
  (interactive)
  (when (hooglel-server-live-p)
    (kill-process (get-buffer-create hooglel-server-buffer-name))))

;;;###autoload
(defun hooglel-lookup-from-local (&optional query)
  "Lookup by local hoogle.  If you set QUERY then search it."
  (interactive)
  (lexical-let
      ((query (typecase query
                (symbol (symbol-name query))
                (string query)
                (null   (read-string "hoogle: " (word-at-point))))))
    (if (hooglel-server-live-p)
        (browse-url (format "https://localhost:%i/?hoogle=%s"
                            hooglel-port-number query))
      (when (y-or-n-p
             "Hoogle server not found, start hoogle server? ")
        (if (executable-find "hoogle")
            (hooglel-start-server)
          (error "Hoogle is not installed"))))))

(defalias 'hooglel 'hooglel-lookup-from-local)

(when (and (fboundp 'ghc-select-completion-symbol)
           (fboundp 'helm))
  (defun helm-hooglel-by-context ()
    (interactive)
    (lexical-let ((c (ghc-select-completion-symbol)))
      (helm :sources
            `((name       . "Helm Haskell")
              (candidates . ,c)
              (action     . (("Find from haddock" . hooglel))))
            :buffer "*helm haskell*"))))

(provide 'hooglel)

;; Local Variables:
;; coding: utf-8
;; mode: emacs-lisp
;; End:

;;; hooglel.el ends here
