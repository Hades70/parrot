;;; parrot.el --- Party Parrot rotates gracefully in mode-line.  -*- lexical-binding: t; -*-

;; Author: Daniel Ting <dp12@github.com>
;; URL: https://github.com/dp12/parrot.git
;; Version: 1.0.0
;; Package-Requires: ((emacs "24.1"))
;; Keywords: party, parrot, rotate, sirocco, kakapo, games

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; To load this file, add (require 'parrot) to your init file. You can display
;; the party parrot in your mode line by adding (parrot-mode).
;;
;; To get the parrot to rotate on new email messages in mu4e, add:
;; (add-hook 'mu4e-index-updated-hook #'parrot-start-animation)
;;
;; This animation code is a heavily modified version of Jacek "TeMPOraL"
;; Zlydach's famous nyan-mode. Check out his original work at
;; https://github.com/TeMPOraL/nyan-mode/.

;;; Code:

(require 'parrot-rotate)

(defconst parrot-directory (file-name-directory (or load-file-name buffer-file-name)))
(defconst parrot-modeline-help-string "mouse-1: Rotate with parrot!")

;; ('v') (*'v') ('V'*) ('v'*)
;; ('v') ('V') ('>') ('^') ('<') ('V') ('v')

(defgroup parrot nil
  "Customization group for `parrot-mode'."
  :group 'frames)

(defun parrot-refresh ()
  "Refresh after option change if loaded."
  (when (featurep 'parrot-mode)
    (when (and (boundp 'parrot-mode)
               parrot-mode)
      (force-mode-line-update))))

(defcustom parrot-animation-frame-interval 0.045
  "Number of seconds between animation frames."
  :type 'float
  :set (lambda (sym val)
         (set-default sym val)
         (parrot-refresh))
  :group 'parrot)

(defvar parrot-animation-timer nil)

(defvar parrot-rotations 0)

(defun parrot-start-animation ()
  "Start the parrot animation."
  (interactive)
  (setq parrot-rotations 0)
  (when (not (and parrot-animate-parrot
                  parrot-animation-timer))
    (setq parrot-animation-timer (run-at-time nil
                                              parrot-animation-frame-interval
                                              #'parrot-switch-anim-frame))
    (setq parrot-animate-parrot t)))

(defun parrot-stop-animation ()
  "Stop the parrot animation."
  (interactive)
  (when (and parrot-animate-parrot
             parrot-animation-timer)
    (cancel-timer parrot-animation-timer)
    (setq parrot-animation-timer nil)
    (setq parrot-animate-parrot nil)))

(defcustom parrot-minimum-window-width 45
  "Determines the minimum width of the window, below which party parrot will not be displayed."
  :type 'integer
  :set (lambda (sym val)
         (set-default sym val)
         (parrot-refresh))
  :group 'parrot)

(defcustom parrot-animate-parrot nil
  "Enable animation for party parrot.
This can be t or nil."
  :type '(choice (const :tag "Enabled" t)
                 (const :tag "Disabled" nil))
  :set (lambda (sym val)
         (set-default sym val)
         (if val
             (parrot-start-animation)
           (parrot-stop-animation))
         (parrot-refresh))
  :group 'parrot)

(defcustom parrot-spaces-before 0
  "Spaces of padding before parrot in mode line."
  :type 'integer
  :set (lambda (sym val)
         (set-default sym val)
         (parrot-refresh))
  :group 'parrot)

(defcustom parrot-spaces-after 0
  "Spaces of padding after parrot in the mode line."
  :type 'integer
  :set (lambda (sym val)
         (set-default sym val)
         (parrot-refresh))
  :group 'parrot)

(defcustom parrot-num-rotations 3
  "How many times party parrot will rotate."
  :type 'integer
  :group 'parrot)

(defvar parrot-frame-list (number-sequence 1 10))
(defvar parrot-type nil)
(defvar parrot-static-image nil)
(defvar parrot-animation-frames nil)

(defun parrot-load-frames (parrot)
  "Load the images for the selected PARROT."
  (when (image-type-available-p 'xpm)
    (setq parrot-static-image (create-image (concat parrot-directory (format "img/%s/%s-parrot-frame-1.xpm" parrot parrot)) 'xpm nil :ascent 'center))
    (setq parrot-animation-frames (mapcar (lambda (id)
                                                  (create-image (concat parrot-directory (format "img/%s/%s-parrot-frame-%d.xpm" parrot parrot id))
                                                                'xpm nil :ascent 'center))
                                                parrot-frame-list))))

(defun parrot-set-parrot-type (parrot)
  "Set the desired PARROT type in the mode line."
  (interactive (list (completing-read "Select parrot: "
                                      '(default confused emacs nyan rotating science thumbsup))))
  (let ((parrot-found t))
    (cond ((string= parrot "default") (setq parrot-frame-list (number-sequence 1 10)))
          ((string= parrot "confused") (setq parrot-frame-list (number-sequence 1 26)))
          ((string= parrot "emacs") (setq parrot-frame-list (number-sequence 1 10)))
          ((string= parrot "nyan") (setq parrot-frame-list (number-sequence 1 10)))
          ((string= parrot "rotating") (setq parrot-frame-list (number-sequence 1 13)))
          ((string= parrot "science") (setq parrot-frame-list (number-sequence 1 10)))
          ((string= parrot "thumbsup") (setq parrot-frame-list (number-sequence 1 12)))
          (t (setq parrot-found nil))
          )
    (if (not parrot-found)
        (message (format "Error: no %s parrot available" parrot))
      (setq parrot-type parrot)
      (parrot-load-frames parrot)
      (run-at-time "0.5 seconds" nil #'parrot-start-animation)
      (message (format "%s parrot selected" parrot)))))

(defvar parrot-current-frame 0)

(defun parrot-switch-anim-frame ()
  "Change to the next frame in the parrot animation.
If the parrot has already
rotated for `parrot-num-rotations', the animation will stop."
  (setq parrot-current-frame (% (+ 1 parrot-current-frame) (car (last parrot-frame-list))))
  (when (eq parrot-current-frame 0)
    (setq parrot-rotations (+ 1 parrot-rotations))
    (when (>= parrot-rotations parrot-num-rotations)
      (parrot-stop-animation)))
  (force-mode-line-update))

(defun parrot-get-anim-frame ()
  "Get the current animation frame."
  (if parrot-animate-parrot
      (nth parrot-current-frame parrot-animation-frames)
    parrot-static-image))

(defun parrot-add-click-handler (string)
  "Add a handler to STRING for animating the parrot when it is clicked."
  (propertize string 'keymap `(keymap (mode-line keymap (down-mouse-1 . ,(lambda () (interactive) (parrot-start-animation)))))))

(defun parrot-create ()
  "Generate the party parrot string."
  (if (< (window-width) parrot-minimum-window-width)
      ""                                ; disabled for too small windows
    (let ((parrot-string (make-string parrot-spaces-before ?\s)))
      (setq parrot-string (concat parrot-string (parrot-add-click-handler
                                                             (propertize "-" 'display (parrot-get-anim-frame)))
                                        (make-string parrot-spaces-after ?\s)))
      (propertize parrot-string 'help-echo parrot-modeline-help-string))))

(defvar parrot-old-cdr-mode-line-position nil)

;;;###autoload
(define-minor-mode parrot-mode
  "Use Parrot to show when you're rotating
You can customize this minor mode, see option `parrot-mode'."
  :global t
  :group 'parrot
  :require 'parrot
  (if parrot-mode
      (progn
        (unless parrot-type (parrot-set-parrot-type 'default))
        (unless parrot-old-cdr-mode-line-position
          (setq parrot-old-cdr-mode-line-position (cdr mode-line-position)))
        (setcdr mode-line-position (cons '(:eval (list (parrot-create)))
                                         (cdr parrot-old-cdr-mode-line-position))))
    (setcdr mode-line-position parrot-old-cdr-mode-line-position)))

(provide 'parrot)

;;; parrot.el ends here
