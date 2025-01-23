;; Caps to escape/control configuration for Kanata

(defcfg
  ;; list devices explicitly to prevent problems with bluetooth mouse
  macos-dev-names-include (
    "Apple Internal Keyboard / Trackpad"
    "TouchBarUserDevice"
    )
  ;; also manage keys not in defsrc list
  process-unmapped-keys yes
  )
  
(defsrc
  esc f1   f2   f3   f4   f5   f6   f7   f8   f9   f10   f11   f12
  caps a s d f j k l ;
)

(defvar
  tap-time 150
  hold-time 200
)

(defalias
  cw (caps-word 5000)
  escctrl (tap-hold 100 100 esc lctl)
  ;; trigger a tap when rolling within the timeout (unless second key is released first)
  ;; don't trigger hold for keys from same side ("bilateral combinations")
  a (tap-hold-except-keys $tap-time $hold-time a lalt (q w e r t a s d f g z x c v b))
  s (tap-hold-except-keys $tap-time $hold-time s lmet (q w e r t a s d f g z x c v b))
  d (tap-hold-except-keys $tap-time $hold-time d lsft (q w e r t a s d f g z x c v b))
  f (tap-hold-except-keys $tap-time $hold-time f lctl (q w e r t a s d f g z x c v b))
  j (tap-hold-except-keys $tap-time $hold-time j rctl (y u i o p h j k l ; n m , . /))
  k (tap-hold-except-keys $tap-time $hold-time k rsft (y u i o p h j k l ; n m , . /))
  l (tap-hold-except-keys $tap-time $hold-time l rmet (y u i o p h j k l ; n m , . /))
  ;; the right-option key must be set to ESC+ in iterm/terminal settings for this mapping to work                                                       
  ; (tap-hold-except-keys $tap-time $hold-time ; ralt (y u i o p h j k l ; n m , . /))
)

(deflayer base
  @cw brdn  brup  _    _    _    _   prev  pp  next  mute  vold  volu
  @escctrl @a @s @d @f @j @k @l @;
)

(deflayer fn
  @cw f1   f2   f3   f4   f5   f6   f7   f8   f9   f10   f11   f12
  @escctrl _ _ _ _ _ _ _ _
)
