;;
;; Copyright (C) 2000 Hitoshi Yamauchi
;;
;;	major mode に影響を与えない方法として overlay があるようだが，
;;      これはかなりめんどうくさい．その上，xemacsでは使えない．
;;
(progn
  (make-face 'a-face)
  (set-face-foreground 'a-face "red")
  (goto-char (point-min))
  (search-forward "Here will be overlaied 2 seconds")
  ;; overlayを作成する
  (setq my-overlay (make-overlay (match-beginning 0) (match-end 0)))
  ;; overlayそこにfaceをputする
  (overlay-put my-overlay 'face 'a-face)
  (sit-for 2)
  ;; overlayを消す
  (delete-overlay my-overlay))


