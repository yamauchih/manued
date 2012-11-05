;;
;;
;; Copyright (C) 2000 Hitoshi Yamauchi
;; @see font-lock-keywords
;;
;; これで foo と bar に font lock をかけることができる
;;
(progn
  (setq my-font-lock-keywords '(("foo\\|bar" 0 font-lock-comment-face t)))
  (make-local-variable 'font-lock-keywords)
  (setq font-lock-keywords
	(append font-lock-keywords
		my-font-lock-keywords)))

(progn
  (setq font-lock-keywords
        (append font-lock-keywords
                (list '("\\(;\\|hahaha\\)" (0 red)))))
  (font-lock-unfontify-buffer)
  (font-lock-fontify-buffer))


;;
;; これで良いのでは?
;;
(defun matcher (dummy)
  (message "here is macher")
  nil)
(progn
  (setq font-lock-keywords nil)
  (setq font-lock-keywords
        (append font-lock-keywords
                (list
		 (list "\\[.*\\]"
		       (list 'matcher 1 font-lock-comment-face)))))
  (font-lock-unfontify-buffer)
  (font-lock-fontify-buffer))


[helloshshsh]

しかし，結局自分でやった方が速そう

関数を呼ぶのはどうかな．

あるいはfont-lockのfillin propertyだけにするのが良いような気がする．



