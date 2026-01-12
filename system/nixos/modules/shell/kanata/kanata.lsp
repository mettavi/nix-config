(defcfg
  ;; linux-dev (
  ;;   "/dev/input/by-id/usb-ITE_Tech._Inc._ITE_Device_8910_-hidraw"
  ;;   "/dev/hidraw0"
  ;;   "/dev/input/by-path/pci-0000:67:00.0-usb-0:4:1.0-hidraw"
  ;;   )
  ;; also manage keys not in defsrc list
  process-unmapped-keys yes
  )

 (defsrc
  esc
  caps a s d f h j k l ;
)

(defvar
  tap-time 150
  hold-time 200
)

(defalias
  nav (layer-while-held navigation)
  ;; spc and other keys will terminate the caps-lock, so typing a sentence will require the key to be reused
  cw (caps-word 5000)
  escnav (tap-hold 100 100 esc @nav)
  ;; trigger a tap when rolling within the timeout (unless second key is released first)
  ;; don't trigger hold for keys from same side ("bilateral combinations")
  a (tap-hold-except-keys $tap-time $hold-time a lalt (q w e r t a s d f g z x c v b))
  s (tap-hold-except-keys $tap-time $hold-time s lmet (q w e r t a s d f g z x c v b))
  d (tap-hold-except-keys $tap-time $hold-time d lsft (q w e r t a s d f g z x c v b))
  f (tap-hold-except-keys $tap-time $hold-time f lctl (q w e r t a s d f g z x c v b))
  j (tap-hold-except-keys $tap-time $hold-time j rctl (y u i o p h j k l ; n m , . /))
  k (tap-hold-except-keys $tap-time $hold-time k rsft (y u i o p h j k l ; n m , . /))
  l (tap-hold-except-keys $tap-time $hold-time l rmet (y u i o p h j k l ; n m , . /))
  ; (tap-hold-except-keys $tap-time $hold-time ; ralt (y u i o p h j k l ; n m , . /))
)

(deflayer base
  @cw
  @escnav @a @s @d @f _ @j @k @l @;
)

(deflayer navigation
  @cw
  _ _ _ _ _ left down up rght _
)
