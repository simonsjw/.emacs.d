(defun display-buffer (buffer-or-name &optional action frame)
  "Display BUFFER-OR-NAME in some window, without selecting it.
To change which window is used, set `display-buffer-alist'
to an expression containing one of these \"action\" functions:

 `display-buffer-same-window' -- Use the selected window.
 `display-buffer-reuse-window' -- Use a window already showing
    the buffer.
 `display-buffer-in-previous-window' -- Use a window that did
    show the buffer before.
 `display-buffer-use-some-window' -- Use some existing window.
 `display-buffer-use-least-recent-window' -- Try to avoid re-using
    windows that have recently been switched to.
 `display-buffer-pop-up-window' -- Pop up a new window.
 `display-buffer-full-frame' -- Delete other windows and use the full frame.
 `display-buffer-below-selected' -- Use or pop up a window below
    the selected one.
 `display-buffer-at-bottom' -- Use or pop up a window at the
    bottom of the selected frame.
 `display-buffer-pop-up-frame' -- Show the buffer on a new frame.
 `display-buffer-in-child-frame' -- Show the buffer in a
    child frame.
 `display-buffer-no-window' -- Do not display the buffer and
    have `display-buffer' return nil immediately.

For instance:

   (setq display-buffer-alist \\='((\".*\" display-buffer-at-bottom)))

Buffer display can be further customized to a very high degree;
the rest of this docstring explains some of the many
possibilities, and also see Info node `(emacs)Window Choice' for
more information.

BUFFER-OR-NAME must be a buffer or a string naming a live buffer.
Return the window chosen for displaying that buffer, or nil if no
such window is found.

Optional argument ACTION, if non-nil, should specify a buffer
display action of the form (FUNCTIONS . ALIST).  FUNCTIONS is
either an \"action function\" or a possibly empty list of action
functions.  ALIST is a possibly empty \"action alist\".

An action function is a function that accepts two arguments: the
buffer to display and an action alist.  Based on those arguments,
it should try to display the buffer in a window and return that
window.  An action alist is an association list mapping symbols
to values.  Action functions use the action alist passed to them
to fine-tune their behaviors.

`display-buffer' builds a list of action functions and an action
alist by combining any action functions and alists specified by
`display-buffer-overriding-action', `display-buffer-alist', the
ACTION argument, `display-buffer-base-action', and
`display-buffer-fallback-action' (in order).  Then it calls each
function in the combined function list in turn, passing the
buffer as the first argument and the combined action alist as the
second argument, until one of the functions returns non-nil.

See above for the action functions and the action they try to
perform.

Action alist entries are:
 `inhibit-same-window' -- A non-nil value prevents the same
    window from being used for display.
 `inhibit-switch-frame' -- A non-nil value prevents any frame
    used for showing the buffer from being raised or selected.
    Note that a window manager may still raise a new frame and
    give it focus, effectively overriding the value specified
    here.
 `reusable-frames' -- The value specifies the set of frames to
    search for a window that already displays the buffer.
    Possible values are nil (the selected frame), t (any live
    frame), visible (any visible frame), 0 (any visible or
    iconified frame) or an existing live frame.
 `pop-up-frame-parameters' -- The value specifies an alist of
    frame parameters to give a new frame, if one is created.
 `window-height' -- The value specifies the desired height of the
    window chosen and is either an integer (the total height of
    the window specified in frame lines), a floating point
    number (the fraction of its total height with respect to the
    total height of the frame's root window), a cons cell whose
    car is `body-lines' and whose cdr is an integer that
    specifies the height of the window's body in frame lines, or
    a function to be called with one argument - the chosen
    window.  That function is supposed to adjust the height of
    the window.  Suitable functions are `fit-window-to-buffer'
    and `shrink-window-if-larger-than-buffer'.
 `window-width' -- The value specifies the desired width of the
    window chosen and is either an integer (the total width of
    the window specified in frame lines), a floating point
    number (the fraction of its total width with respect to the
    width of the frame's root window), a cons cell whose car is
    `body-columns' and whose cdr is an integer that specifies the
    width of the window's body in frame columns, or a function to
    be called with one argument - the chosen window.  That
    function is supposed to adjust the width of the window.
 `window-size' -- This entry is only useful for windows appearing
    alone on their frame and specifies the desired size of that
    window either as a cons of integers (the total width and
    height of the window on that frame), a cons cell whose car is
    `body-chars' and whose cdr is a cons of integers (the desired
    width and height of the window's body in columns and lines of
    its frame), or a function to be called with one argument -
    the chosen window.  That function is supposed to adjust the
    size of the frame.
 `preserve-size' -- The value should be either (t . nil) to
    preserve the width of the chosen window, (nil . t) to
    preserve its height or (t . t) to preserve its height and
    width in future changes of the window configuration.
 `window-parameters' -- The value specifies an alist of window
    parameters to give the chosen window.
 `allow-no-window' -- A non-nil value means that `display-buffer'
    may not display the buffer and return nil immediately.
 `body-function' -- A function called with one argument - the
    displayed window.  It is called after the buffer is
    displayed, and before `window-height', `window-width'
    and `preserve-size' are applied.  The function is supposed
    to fill the window body with some contents that might depend
    on dimensions of the displayed window.

The entries `window-height', `window-width', `window-size' and
`preserve-size' are applied only when the window used for
displaying the buffer never showed another buffer before.

The ACTION argument can also have a non-nil and non-list value.
This means to display the buffer in a window other than the
selected one, even if it is already displayed in the selected
window.  If called interactively with a prefix argument, ACTION
is t.  Non-interactive calls should always supply a list or nil.

The optional third argument FRAME, if non-nil, acts like a
\(reusable-frames . FRAME) entry appended to the action alist
specified by the ACTION argument."
  (interactive (list (read-buffer "Display buffer: " (other-buffer))
		     (if current-prefix-arg t)))
  (let ((buffer (if (bufferp buffer-or-name)
		    buffer-or-name
		  (get-buffer buffer-or-name)))
        (buf-name (if (bufferp buffer-or-name)
                      (buffer-name buffer-or-name)
                    buffer-or-name))
	;; Make sure that when we split windows the old window keeps
	;; point, bug#14829.
	(split-window-keep-point t)
	;; Handle the old form of the first argument.
	(inhibit-same-window (and action (not (listp action)))))
    (unless (listp action) (setq action nil))
    (let* ((user-action
            (display-buffer-assq-regexp
             buf-name display-buffer-alist action))
           (special-action (display-buffer--special-action buffer))
           ;; Extra actions from the arguments to this function:
           (extra-action
            (cons nil (append (if inhibit-same-window
                                  '((inhibit-same-window . t)))
                              (if frame
                                  `((reusable-frames . ,frame))))))
           ;; Construct action function list and action alist.
           (actions (list display-buffer-overriding-action
                          user-action special-action action extra-action
                          display-buffer-base-action
                          display-buffer-fallback-action))
           (functions (apply 'append
                             (mapcar (lambda (x)
                                       (setq x (car x))
                                       (if (functionp x) (list x) x))
                                     actions)))
           (alist (apply 'append (mapcar 'cdr actions)))
           window)
      (unless (buffer-live-p buffer)
        (error "Invalid buffer"))
      (while (and functions (not window))
        (setq window (funcall (car functions) buffer alist)
              functions (cdr functions)))
      (and (windowp window) window))))
