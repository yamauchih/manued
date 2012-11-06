;;;
;;; manued.el --- a minor mode of manued proofreading method.
;;;
;;; Author: Hitoshi Yamauchi
;;; Maintainer: Hitoshi Yamauchi
;;; Created: 16 Jan 1998
;;; Keywords: proofreading, docs
;;;
;;; Contributors: Atusi Maeda
;;;	          Stefan Monnier (0.9.1)
;;;	          Mikio Nakajima (0.9.3)
;;;	          Takao Kawamura (0.9.3)
;;;
;;; This file is not part of GNU Emacs.
;;;
;;; This program is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either versions 2, or (at your option)
;;; any later version.
;;;
;;; This program is distributed in the hope that it will be useful
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;; see <http://www.gnu.org/licenses/>.
;;;

;;;
;;; Manued stands for MANUscripting EDitor.
;;;
;;; Original idea of manued:
;;;	Ikuo Takeuchi, ``Manuscripting Editing on E-mail,'' 39th
;;;	Programming Symposium, 1998, January, pp.61--68
;;;
;;;	The original paper is written in Japanese,
;;;	竹内郁雄, ``電子メールで原稿を修正する方法 --- Manuscript
;;;     Editing (Manued, 真鵺道)を目指して ---'', 第 39 回プログラミン
;;;	グシンポジウム, 1998, 1月, pp.61--68
;;;
;;;
;;------------------------------------------------------------
;; debug 用の message 出力
;;------------------------------------------------------------
;; delete at release
;;(setq debug-on-error t)
;;(defun dbg (mes) (print mes (get-buffer "manued-debug")))

;;------------------------------------------------------------
;; constant values
;;------------------------------------------------------------
(defconst manued-version-num   "0.9.5-current"
  "The version of manued.el.
真鵺道のバージョン")

(defconst manued-build-day "2002-8-12"
  "The day of last change of manued.el.
真鵺道の最終更新日")

(defconst manued-formatted-buffer-name "*manued*"
  "Buffer name of formatted manued text.
真鵺道の整形済みバッファ名")

;;------------------------------
;; What kind of emacs is this?
;;------------------------------
(defconst manued-xemacs-p
  (and (featurep 'mule) (string-match "XEmacs" emacs-version))
  "Non-nil when running on XEmacs.")

;;;------------------------------------------------------------
;;; some useful macros
;;;------------------------------------------------------------

;;------------------------------------------------------------
;; convenient funcs for pstr (points with string region)
;;	pstr = (command-begin-point command-end-point command-str)
;;------------------------------------------------------------
(defmacro manued-get-first-point (pstr)
  "pstr からコマンドの初めの point を返す"
  `(car ,pstr))

(defmacro manued-get-end-point (pstr)
  "pstr からコマンドの終わりの point を返す"
  `(car (cdr ,pstr)))

(defmacro manued-get-command-str (pstr)
  "pstr からコマンド文字列を返す"
  `(car (cdr (cdr ,pstr))))

(defmacro manued-command-eq (pstr command-chars)
  "pstr 中のコマンド文字列がコマンド文字列(command-chars)と一致する場
合に t を返す"
  `(string-equal
    (manued-get-command-str ,pstr) ,command-chars))

;;;------------------------------------------------------------
;;; manued version
;;;------------------------------------------------------------
(defun manued-show-version ()
  "Print manued version.
manued のバージョンを知らせる."
  (interactive)
  (cond ((interactive-p)
         (message "Manued version %s of %s"
		  manued-version-num manued-build-day))))

;;;
;;; Variable declarations
;;;
;;------------------------------
;; related manued command variables
;;------------------------------
(defvar manued-l-parenthesis-str "["
  "* Start string of manued command. : default is `['
真鵺道のコマンドのはじまりを示す文字列")
(make-variable-buffer-local 'manued-l-parenthesis-str)

(defvar manued-r-parenthesis-str "]"
  "* End string of manued command. : default is `]'
真鵺道のコマンドの終了を示す文字列")
(make-variable-buffer-local 'manued-r-parenthesis-str)

(defvar manued-swap-str "|"
  "* String of manued swap-command. : default is '|'
	'A|B|C' means to swap A with C, then A|B|C will be C|B|A.
	Especially, 'A||C' means to swap A and C, then A||C will be C||A.
交換コマンド文字列 : デフォルトは '|':
	A|B|C ならば A と C を入れ換える．したがって A|B|C は C|B|A となる．
	特に 'A||C' は A と C の入れ換えを意味する．したがって，
	A||C は C||A となる．")
(make-variable-buffer-local 'manued-swap-str)

(defvar manued-delete-str "/"
  "* String of manued delete-command . : default is '/'
	'A/B' means to substitute A by B, then A/B will be B.
	Especially, '/B' means to insert B and 'A/' means to delete A.
消去コマンド文字列 デフォルトは '/':
	A/B ならば A を B で置き換える．
	特に '/B' は B の挿入を意味し，'A/' は A の削除を意味する.")
(make-variable-buffer-local 'manued-delete-str)

(defvar manued-comment-str ";"
  "* String of maenud comment command. : default is `;'
comment out until manued-r-parenthesis-str.
コメント文字． デフォルトは ';':
	真鵺道コマンドの終りまでをコメントとみなす．")
(make-variable-buffer-local 'manued-comment-str)

(defvar manued-escape-str "~"
  "* Escape string. : default is `~'
This string can escape a next adjacent manued command.
エスケープ文字．デフォルトは '~':
	次の真鵺道コマンド文字をエスケープする．")
(make-variable-buffer-local 'manued-escape-str)

(defvar manued-pretty-print-format-delete-list
  '("\\textnormal{%s}" "\\textbf{%s}" "\\textit{%s}")
  "* manued pretty print format strings list for delete command.
'(delete-part-format replaced-part-format comment-part-format)
as the default, [A/B;C] will be print out:
  \\textnormal{A}\\textbf{B}\\textit{C}
消去コマンド用の pretty print の際に利用される format のリスト
デフォルトでは，[A/B;C] は次のように出力される:
  \\textnormal{A}\\textbf{B}\\textit{C}")
(make-variable-buffer-local 'manued-pretty-print-format-delete-list)

(defvar manued-pretty-print-format-swap-list
  '("\\textbf{%s}---" "\\textbf{%s}" "---\\textbf{%s}" "(\\textit{%s})")
  "* manued pretty print format strings list for swap command.
'(alpha-part-format beta-part-format gamma-part-format comment-part-format)
as the default, [A|B|C;D] will be print out:
 \\textbf{%s}---\\textbf{%s}---\\textbf{%s}(\\textit{%s})
交換コマンド用の pretty print の際に利用される format のリスト
デフォルトでは，[A|B|C;D] は次のように出力される:
 \\textbf{%s}---\\textbf{%s}---\\textbf{%s}(\\textit{%s})
")
(make-variable-buffer-local 'manued-pretty-print-format-swap-list)

(defvar manued-pretty-print-on-p nil
  "* manued pretty print on.
If this is t, you will get revised/original document with pretty
print style. The style will be changed by variables
manued-pretty-print-format-swap-list and
manued-pretty-print-format-delete-list.
pretty print を off にする．
もしこの値が t の場合には，文書を整形した場合に pretty print style で
出力されます．そのスタイルは変数 manued-pretty-print-format-swap-list と
manued-pretty-print-format-delete-list で制御されます．")
(make-variable-buffer-local 'manued-pretty-print-on-p)

(defvar manued-pretty-print-null-comment-out-p nil
  "* When t and there is no comment part, comment is considered as
\"\" and output comment part in pretty print mode. When nil and there
is no comment part, no output for comment part. Notice. This is not
buffer local variable.
この値が t の場合でかつコメントが無い場合，空のコメントがあると考えて
format の引数に \"\" が渡され，出力されます．もしこの変数が nil の場合で
コメント部分が存在しない場合には，コメント部分は出力されません．
この変数は buffer local ではありません．")

(defconst manued-defversion-str manued-version-num
  "* String of manued version number. : default is same as version
number of this code.
バージョン番号を示す文字 : デフォルトはこのコードのバージョン番号")

;;------------------------------
;; related `Find and set def* pattern'.
;;------------------------------
(defvar manued-doc-begin-pat "-*-*- BEGINMANUED -*-*-"
  "* This pattern indicates the beginning of a manued document.
Default is `-*-*- BEGINMANUED -*-*-'. There is no such pattern in
the document, start point of the manued document is set to `point-min'.
When this variable is nil, beginning point is always `point-min'.

真鵺道の文書の最初を示す文字列．この文字列が文書中に存在しない場合には
`point-min' が先頭として用いられる．また，このシンボルが nil の場合に
は常に `point-min' が真鵺道文書の始まりとみなされる．")
(make-variable-buffer-local 'manued-doc-begin-pat)

(defvar manued-doc-end-pat "-*-*- ENDMANUED -*-*-"
  "* This pattern indicates end of a manued document.
default is `-*-*- ENDMANUED -*-*-'. There is no such pattern in
the document, enx d point of the manued document is set to `point-max'.
When this variable is nil, beginning point is always `point-max'.

真鵺道の文書の最後を示す文字列．この文字列が文書中に存在しない場合には
`point-max' が最後として用いられる．また，このシンボルが nil の場合に
は常に `point-max' が真鵺道文書の始まりとみなされる．")
(make-variable-buffer-local 'manued-doc-end-pat)

(defconst manued-def-alist
  '(("defLparenthesis"	manued-l-parenthesis-str)
    ("defRparenthesis" 	manued-r-parenthesis-str)
    ("defswap"		manued-swap-str)
    ("defdelete"	manued-delete-str)
    ("defcomment"	manued-comment-str)
    ("defescape"	manued-escape-str)
    ("deforder"		manued-order-str)
    ("defversion"	manued-defversion-str))
  "manued command definition strings and symbols
真鵺道のコマンド宣言定義文字列とそのシンボル")

(defvar manued-defcommand-head-str-list
  '("%" "%%"				; for TeX
    )
  "list of manued defcommand header strings.
This strings are ignored when they added at head of manued command
definition string.

There is some cases that we want to comment out the manued
defcommands, for example using manued in TeX document. We can write
defcommands like below.

	%%defparentheses [ ]
	%%defdelete	 /

These defcommands are recognized by manued.el and TeX ignore these
commands.

この文字列のリストには，真鵺道のコマンド宣言定義文字列の前に付加した場
合に無視する文字列を含める．たとえば TeX の文書中で真鵺道を利用する場
合，以下のように真鵺道定義コマンドを TeX のコメント部に含める

	%%defparentheses [ ]
	%%defdelete	 /

こうすると，manued.el はこれを defcommand として認識し，さらに TeX で
はこの部分を無視するので，透過的に manued を利用可能である．")
(make-variable-buffer-local 'manued-defcommand-head-str-list)

;;--------------------
;; hilit related defvar
;;--------------------
(defvar manued-use-color-hilit 'follow-font-lock-mode
  "t when using color hilit. However `window-system' is nil, this
value is set to nil. When this is 'follow-font-lock-mode, follow font
lock mode.

色を使ってハイライトする場合には t，ただし，window-system が nil の場
合には nil がセットされる．'follow-font-lock-mode の場合には
font-lock-modeに従う．")
(make-variable-buffer-local 'manued-use-color-hilit)

;; hilit color
(defvar manued-first-hilit-color-list
  '("red"				; delete first color
    "gray60"				; delete last color
    "blue"				; swap alpha color
    "red"				; swap beta  color
    "green4"				; swap gamma color
    "BlueViolet"			; comment color
    "gray60")				; command color
  "* hilit for first part of command.")
(make-variable-buffer-local 'manued-first-hilit-color-list)

(defvar manued-last-hilit-color-list
  '("gray60"				; delete first color
    "red"				; delete last color
    "blue"				; swap alpha color
    "red"				; swap beta  color
    "green4"				; swap gamma color
    "BlueViolet"			; comment color
    "gray60")				; command color
  "* hilit for last part of command")
(make-variable-buffer-local 'manued-last-hilit-color-list)

;;------------------------------
;; insert command related variables
;;------------------------------
(defvar manued-is-delete-command-with-comment-on t
  "Control insert-delete-command inserts one comment command or not.

When manued-is-delete-command-with-comment-on is t.
	manued-insert-delete-command                ... insert comment
	manued-insert-delete-command-toggle-comment ... not insert comment
When manued-is-delete-command-with-comment-on is nil.
	manued-insert-delete-command                ... not insert comment
	manued-insert-delete-command-toggle-comment ... insert comment

真鵺道 command 内部でコメント文字を挿入するかしないかを制御する．t の
時には default で manued-insert-delete-command はコメント文字を挿入する．た
だし，manued-insert-delete-command-toggle-comment コマンドは逆の動作をする．
")
(make-variable-buffer-local 'manued-is-delete-command-with-comment-on)

(defvar manued-is-swap-command-with-comment-on t
  "Control insert-swap-command inserts one comment command or not.

When manued-is-swap-command-with-comment-on is t.
	manued-insert-swap-command                ... insert comment
	manued-insert-swap-command-toggle-comment ... not insert comment
When manued-is-swap-command-with-comment-on is nil.
	manued-insert-swap-command                ... not insert comment
	manued-insert-swap-command-toggle-comment ... insert comment

真鵺道 command 内部でコメント文字を挿入するかしないかを制御する．t の
時には default で manued-insert-swap-command はコメント文字を挿入する．た
だし，manued-insert-swap-command-toggle-comment コマンドは逆の動作をする．
")
(make-variable-buffer-local 'manued-is-swap-command-with-comment-on)


;;============================================================
;; Find and set def* pattern.
;;============================================================
;;
;; def* の後ろに続く非空白文字何文字かをその def のパターンとする
;; 現在は以下のものをサポートする．後ろのものは default 値
;;
;; 	defparentheses  [ ]
;; 	; defLparenthesis [	(will be obsoleted but now support)
;; 	; defRparenthesis ]	(will be obsoleted but now support)
;; 	defswap 	|
;; 	defdelete 	/
;; 	defcomment 	;
;;	defescape  	~
;;	defversion  	manued-version-num
;;
;;
;; 最初は位置のキャッシュはしないことにする
;; 次は編集されたかどうかを見るようにする
;;
;(defvar manued-doc-begin-point nil
;  "The cache of the beginnig point of manued document.
;   真鵺道文書のスタートポイントのキャッシュ")
;(defvar manued-doc-end-point nil
;  "The cache of the end point of manued document.
;  真鵺道文書のエンドポイントのキャッシュ")

;;
;; 真鵺道文書のはじめを探す
;;
(defun manued-get-doc-begin-point ()
  "Find beggining point of the manued document.
Find beginning pattern of a manued document and return the point. If
begging pattern is not founded in the manued document, return the
`point-min'. The beginning pattern is `manued-doc-begin-pat'.

真鵺道文書の最初の位置を探し，そのポイントを返す．もし真鵺道文書中に真
鵺道文書開始パターンがみつからない場合には文書の最初 `point-min' へ飛
ぶ．真鵺道文書開始パターンは `manued-doc-begin-pat' が保持している．"
  (if (null manued-doc-begin-pat)
      (point-min)
    (save-excursion
      (goto-char (point-min))
      (if (search-forward manued-doc-begin-pat nil t)
	  (match-beginning 0)		; found
	(point-min)))))			; not found

;;
;; 真鵺道文書の終わりを探す
;;
(defun manued-get-doc-end-point ()
  "Find end point of the manued document.
Find end pattern of a manued document and return the point. If
end pattern is not founded in the manued document, return the
`point-max'. The end pattern is `manued-doc-end-pat'.

真鵺道文書の終わりの位置を探し，そのポイントを返す．もし真鵺道文書中に
真鵺道文書開始パターンがみつからない場合には文書の最初 `point-min' へ
飛ぶ．真鵺道文書開始パターンは `manued-doc-begin-pat' が保持している．
"
  (if (null manued-doc-end-pat)
      (point-max)
    (save-excursion
      (goto-char (point-max))
      (if (search-backward manued-doc-end-pat nil t)
	  (match-end 0)			; found
	(point-max)))))			; not found

;;;------------------------------
;;; defcommand を探してセットする
;;;------------------------------
;; 一引数の一つの defcommand を探してセットする
(defun manued-search-set-def-one (decstr-str)
  "Find a manued command definition string `decstr-str' and set manued
command pattern.
See also the `manued-def-alist' which is a list of manued command
declarations and variables.

一つの真鵺道コマンド宣言文字列 `decstr-str' を探してその文字列に対応す
る文字列をセットする．
`manued-def-alist' が真鵺道コマンド宣言文字列とその変数を保持している
ので参照のこと．"
  (let ((non-whitespace-pat "[ |\t]+\\([^ |\t|$\n]+\\)"))
    (if (re-search-forward
	 (concat "^" (car decstr-str) non-whitespace-pat) nil t)
	(progn
	  (let ((b (match-beginning 1))	(e (match-end 1)))
	    (if (< b e)
		(set (car (cdr decstr-str))
		     (buffer-substring-no-properties b e))))))))

;; 二引数の一つの defcommand を探してセットする
(defun manued-search-set-defparentheses-with-comment (comment-str)
  "Find defparentheses and set values. This method is for
defparentheses only.

defparentheses を探し，値をセットする．comment-str を先頭に付加する文
字列．"
  (if (re-search-forward
       (concat "^" comment-str "defparentheses[ |\t]+") nil t)
      ;; 空白でない2つの引数を探す．このregexを複数重ねていけば指定
      ;; 個の引数を扱うことにはなる
      (if (looking-at "\\([^ |\t|$\n]+\\)[ |\t]+\\([^ |\t|$\n]+\\)")
	  (progn
	    (setq manued-l-parenthesis-str
		  (buffer-substring-no-properties
		   (match-beginning 1) (match-end 1)))
	    (setq manued-r-parenthesis-str
		  (buffer-substring-no-properties
		   (match-beginning 2) (match-end 2))))
	(error (format ":Two arguments are needed for defparentheses."))
	nil)
    nil))

;;
;; 全ての defcommand をセットする
;;
(defvar manued-header-is-found nil)	; header が真鵺道文書中にあるか
(defun manued-search-set-defcommands ()
  "find all manued command declarations in a dcument.
全ての真鵺道コマンド宣言文字列を文書中から探し出し，真鵺道コマンドをセッ
トする．
See also `manued-search-set-oneargdefs'."
  ;; headerを再び探す
  (setq manued-header-is-found nil)
  ;; defparentheses を探しセットする :
  (manued-search-set-defparentheses)
  ;; 一引数の def* を探しセットする
  (manued-search-set-oneargdefs manued-def-alist))

;;
;; defparentheses を探しその値をセットする :
;;  これだけdefcommandの中で2引数なので別にする．他に複数引数のものが
;;  出てくれば全てのdefcommandは複数引数として一般化して対処すべきだが，
;;  今はこれしかないので多少add-hocではあるが，このように対処した．
;;
(defun manued-search-set-defparentheses ()
  (goto-char (manued-get-doc-begin-point)) ; goto begin
  (if (manued-search-set-defparentheses-with-comment "") ; serach and set one
      (setq manued-header-is-found t)       ; 素の defparentheses を発見
    ;; defparentheses が素で存在しない場合コメント文字を加えてみる
    (let ((comment-head-list manued-defcommand-head-str-list))
      (while comment-head-list
	(if (manued-search-set-defparentheses-with-comment
	     (car comment-head-list))
	    (progn		; コメント + コマンドが存在した
	      (setq comment-head-list nil)
	      (setq manued-header-is-found t))
	  (setq comment-head-list (cdr comment-head-list)))))))

;;
;; manued-doc-begin-pat から初めて manued-def-alist 中のパターンに合致
;; する文字列を探しその引数をセットする．一引数のdefcommandのみを扱う．
;;
(defun manued-search-set-oneargdefs (def-alist)
  "find one argument manued command declarations in a dcument.
一引数の真鵺道コマンド宣言文字列を文書中から探し出し，真鵺道コマンドを
セットする．
See also `manued-search-set-def-one'."
  (while def-alist
    (goto-char (manued-get-doc-begin-point)) ; goto begin
    (let ((defcom (car def-alist)))
      (if (manued-search-set-def-one defcom) ; serach and set one
	  (setq manued-header-is-found t)   ; 素の defcommand を発見
	;; defcommand が素で存在しない場合コメント文字を加えてみる
	(let ((comment-head-list manued-defcommand-head-str-list))
	  (while comment-head-list
	    (if (manued-search-set-def-one
		 (cons (concat (car comment-head-list) (car defcom))
		       (cdr defcom)))
		(progn		; コメント + コマンドが存在した
		  (setq comment-head-list nil)
		  (setq manued-header-is-found t))
	      (setq comment-head-list (cdr comment-head-list)))))
	;; else list の要素があるだけ繰り返す
	))
    (setq def-alist (cdr def-alist)))
  ;; 古いバージョンのものと互換を持たせるための作業を行う
  (manued-dispatch-for-old-version)
  ;; defcommand の一貫性は保たれているか
  (manued-check-defcommand-consistency)
  ;; 全て defcommand をセットしたら order を決める (deforder を反映させる)
  (manued-set-order-from-order-str)
  manued-header-is-found)

;;
;; It is error when the same strings are used in defcommand.
;;	ex. Error if l-parenthesis-str and r-parenthesis-str are the
;;	same string.
;;
(defun manued-check-defcommand-consistency ()
  (let ((compared-list manued-def-alist))
    (while (not (null compared-list))
      (let* ((compared-def (car compared-list))
	     (target-list (cdr compared-list))
	     (compared-str nil)
	     (target-str   nil))
	(while (not (null target-list))
	  (let* ((target-def (car target-list))
		 (s0 (symbol-value (car (cdr compared-def))))
		 (s1 (symbol-value (car (cdr target-def)))))

	    (if (<= (length s0) (length s1))
		(progn
		  (setq compared-str s0)
		  (setq target-str (substring s1 0 (length s0))))
	      (progn
		(setq compared-str (substring s0 0 (length s1)))
		(setq target-str s1)))
	    (if (string-equal compared-str target-str)

;;	    (if (string-equal s0 s1)
		(progn
		  (goto-char (manued-get-doc-begin-point))
		  (if (search-forward (car compared-def) nil t)
		      (setq hilit-err-occur-pos (match-beginning 0)))
		  (error (format
			  "%s and %s are the same, check your defcommand."
			  (car compared-def) (car target-def))))))
	  (setq target-list (cdr target-list))))
      (setq compared-list (cdr compared-list)))))

;;;------------------------------------------------------------
;;; manued-order-str の値によって order を決める
;;;------------------------------------------------------------
;; order indicating string
(defvar manued-order-str "older-first"
  "* delete order.
The form of the manued command is [first/last]. ``older''
indicates original document and ``newer'' indicates revised
document. This string sets the variable `manued-is-order-older-first'.

真鵺道消去コマンドの適用順．消去コマンドの内容を [first/last]
とする． `older' は元文書を，`newer' は変更後の文書を示す．この文字列
にしたがって `manued-is-order-older-first' の値がセットされる．

-------------------------+-----------------+----------------------------
manued-order-str         | change from to  | manued-is-order-older-first
-------------------------+-----------------+----------------------------
 older-first, newer-last |  first -> last  |           t
 older-last,  newer-first|  last  -> first |          nil
-------------------------+-----------------+----------------------------")

(defvar manued-is-order-older-first t
  "Applying swap-command order.
When t, [first/last] will change first -> last.

消去コマンドの [first/last] のどちらが訂正先かを示す．
[訂正前/訂正後]の場合に t，その逆 ([訂正後/訂正前]) の時に nil．")

;;
;; set delete command order according to order string
;;	order 文字列に従って delete command の前後を決定する
;;
(defun manued-set-order-from-order-str ()
  "set delete command order according to order string."
  (cond ((member manued-order-str '("older-first" "newer-last"))
	 (setq manued-is-order-older-first t))
	((member manued-order-str '("older-last" "newer-first"))
	 (setq manued-is-order-older-first nil))
	(t
	 (setq manued-order-str "older-first")
	 (setq manued-is-order-older-first t)
	 (goto-char (manued-get-doc-begin-point))
	 (search-forward "deforder")
	 (setq hilit-err-occur-pos (match-beginning 0))
	 (error (format "illeal deforder str (setted %s)" manued-order-str)))))

;;------------------------------------------------------------
;; insert manued header
;;------------------------------------------------------------
(defvar manued-is-auto-insert-header '(t t nil)
  "setting for defcommands insertion

'(is-auto-insert is-query-when-insert insert-point)

When `is-auto-insert' is t, manued.el inserts defcommands in the
current buffer in the case of no defcommands in the buffer.  If
`is-auto-insert' is nil, manued.el does not insert defcommands.

When the second element `is-query-when-insert' is t, manued.el asks to
user `insert-manued header (y or n)', otherwise no question. This is
only effective when `is-auto-insert' is t.

The third element of this list `insert-point' indicates insert point
of defcommands. The meaning of value is as folowing.

    t         current point
    nil       (point-min)
    number    point as a number

バッファに defcommand を挿入する場合の設定

`is-auto-insert' が t の場合，もし現在のバッファにdefcommandが無い場合に
はmanued.elはdefcommandを現在のバッファに挿入します．nilの場合には何もし
ません．

2番目の要素`is-query-when-insert'がtの場合，manued.elはユーザに
defcommandを挿入して良いか尋ねるようになります．nilの場合には尋ねません．
これは，`is-auto-insert'がtの場合に有効です．

3番目の要素である`insert-point'はdefcommandの挿入位置を指定するもので，
次のような意味を持ちます．

    t         現在のポイント
    nil       (point-min)
    number    数字で示したpoint位置
")

(defun manued-insert-header (p)
  "insert manued header at point"
  (interactive "d")
  (goto-char p)
  (insert (format "defparentheses\t%s %s\n"
		  manued-l-parenthesis-str manued-r-parenthesis-str))
  (let ((defalist manued-def-alist) (item))
    (while defalist
      (setq item (car defalist))
      (or (member (car item) '("defLparenthesis" "defRparenthesis"))
	  (insert
	   ;; (format "%s\t%s\n" (car item) (eval (car (cdr item)))))
	   ;; と eval を使っていたが，symbol-value を使う
	   (format "%s\t%s\n" (car item) (symbol-value (car (cdr item))))))
      (setq defalist (cdr defalist)))))
;;
;; when non exist header,  insert manued header with quary
;;
(defun manued-search-and-insert-header ()
  "真鵺道 def コマンドをサーチし，存在しない場合には挿入するか尋ねる．

see variable : manued-is-auto-insert-header"
  (save-excursion
    (if (and (car manued-is-auto-insert-header)
	     (not manued-header-is-found)) ; mode に入る際に必ず呼ばれている
	(let ((p) (iposinfo (car (cdr (cdr manued-is-auto-insert-header)))))
	  (cond ((eq t iposinfo)
		 (setq p (point)))
		((null iposinfo)
		 (setq p (point-min)))
		((and (numberp iposinfo) (> iposinfo 0))
		 (setq p iposinfo)))
	  (if (car (cdr manued-is-auto-insert-header))
	      (if (y-or-n-p "insert manued header?")
		  (manued-insert-header p))
	    (manued-insert-header p))))))

;;============================================================
;; hilit manued commands
;;============================================================
;; recenter hilit
;;------------------------------
(defun manued-recenter-hilit ()
  "recenter and hilit

When color mode is enable, recenter and hilight. But when color mode
is disabled, only recenter.

recenter した後に真鵺道コマンドを hilit する．ただし，hilit を行うのは
color mode が off の時のみ．"
  (interactive)
  (manued-hilit)
  (recenter))

;;------------------------------
;; 現在 hilit すべきものを示す.
;; manued-hilit が呼ばれた時にはこの変数を見て hilit-older か
;; hilit-newer かを判定する．t のときには newer を hilit する．
;;------------------------------
(defvar manued-is-now-hilit-newer t)

;;------------------------------
;; hilit
;;------------------------------
(defun manued-hilit ()
  "hilit manued command.
When `manued-use-color-hilit' is t, hilit manued command according to
the value of `manued-is-now-hilit-newer'.

真鵺道コマンドを hilit する．
もし `manued-use-color-hilit' が t ならば manued command を hilit する．
この時，`manued-is-now-hilit-newer' が t ならば newer を hilit し，nil
ならば older を hilit する．"
  (if (manued-guess-color-mode)
      (progn
	(if manued-is-now-hilit-newer
	    (manued-hilit-newer)
	  (manued-hilit-older)))
    (manued-unhilit-current-buffer)))

;;------------------------------
;; unhilit current buffer
;;------------------------------
(defun manued-unhilit-current-buffer ()
  (remove-text-properties (point-min) (point-max) '(face nil)))

;;
;; hilit newer
;;
(defun manued-hilit-newer ()
  "hilit newer part within manued command.
文章中の真鵺道コマンド中の訂正後部分をハイライトする．"
  (interactive)
  (let ((hilit-err-occur-pos nil))
    (condition-case err-message
	(save-excursion
	  (manued-init-vars)
	  (goto-char (manued-get-doc-begin-point))
	  (setq manued-is-now-hilit-newer t)
	  (if manued-is-order-older-first
	      (manued-set-hilit-color manued-last-hilit-color-list)
	    (manued-set-hilit-color manued-first-hilit-color-list))
	  (while (manued-hilit-manuedexp)))
      (error       ; error handling
       (if hilit-err-occur-pos
	   (goto-char hilit-err-occur-pos))
       (error (format "Error! : manued-hilit-newer : %s" err-message))))))

;;
;; hilit older
;;
(defun manued-hilit-older ()
  "hilit older part within manued command.
文章中の真鵺道コマンド中の訂正前部分をハイライトする．"
  (interactive)
  (let ((hilit-err-occur-pos nil))
    (condition-case err-message
	(save-excursion
	  (manued-init-vars)
	  (goto-char (manued-get-doc-begin-point))
	  (setq manued-is-now-hilit-newer nil)
	  (if manued-is-order-older-first
	      (manued-set-hilit-color manued-first-hilit-color-list)
	    (manued-set-hilit-color manued-last-hilit-color-list))
	  (while (manued-hilit-manuedexp)))
      (error       ; error handling
       (if hilit-err-occur-pos
	   (goto-char hilit-err-occur-pos))
       (error (format "Error! : manued-hilit-older : %s" err-message))))))

;;
;; hilit toplevel (hilit-manuedexp see manued.grammer)
;;	lap ... LookAhead Pstr
;;
(defun manued-hilit-manuedexp ()
  "hilit all manued command at top level.
真鵺道の文書中のコマンドを全てハイライトする．"
  (let ((cont t))
    (while cont
      (let ((lap (manued-search-nonescaped-command-in-hirabun ; [ を探す
		  (manued-get-doc-end-point))))
	(if lap				; found [. この lap は [ である
	    (progn
	      (manued-hilit-one-command lap)
	      ;; colored-pos-pstr はこれまで色を塗った場所を示す大域的
	      ;; ポインタ，最初の region は delete-first と仮定する
	      (let ((colored-pos-pstr lap))
		(manued-hilit-manued-term 'manued-com-delete-first)))
	  (setq cont nil))))))		; not found

;;
;; hilit manued-term : LL(1), see Dragon book.
;;
(defun manued-hilit-manued-term (cur-command)
  (let ((cont t)
	(lap nil))			; lookahead-pstr
    (while cont
      (setq lap (manued-search-nonescaped-command
		 (manued-all-command-pat) (manued-get-doc-end-point)))
      (if (null lap)
	  ;; No command is found. At least, `]' must be found here.
	  ;; This must be error.
	  (progn
	    (manued-hilit-can-not-find-end-paren colored-pos-pstr)
	    (setq cont nil))
	(progn
	  (manued-hilit-one-command lap) ; コマンド処理
	  ;; これまでの範囲を処理
	  (cond
	   ;; ; comment in and exit this level
	   ((manued-command-eq lap manued-comment-str)
	    (if (or (eq cur-command 'manued-com-delete-first)
		    (eq cur-command 'manued-com-delete-last)
		    (eq cur-command 'manued-com-swap-gamma))
		(progn (manued-hilit-one-region
			colored-pos-pstr lap cur-command)
		       ;; 次の cur-command は hilit-commet がコメント
		       ;; ということを知っているので冗長だが，プログラ
		       ;; ムとしての一貫性を取るためにあえて setq する
		       (setq cur-command 'manued-com-comment)
		       (manued-hilit-comment lap)
		       (setq cont nil))
	      (progn
		(setq hilit-err-occur-pos (manued-get-first-point lap))
		(error "illegal command, is command right?"))))

	   ;; [ recursion
	   ((manued-command-eq lap manued-l-parenthesis-str)
	    (manued-hilit-one-region colored-pos-pstr lap cur-command)
	    (manued-hilit-manued-term 'manued-com-delete-first))

	   ;; / delete
	   ((manued-command-eq lap manued-delete-str)
	    (manued-hilit-one-region colored-pos-pstr lap cur-command)
	    (setq cur-command 'manued-com-delete-last))

	   ;; | swap
	   ((manued-command-eq lap manued-swap-str)
	    (cond
	     ((eq cur-command 'manued-com-delete-first)
	      (setq cur-command 'manued-com-swap-alpha) ; ここでswapとわかる
	      (manued-hilit-one-region colored-pos-pstr lap cur-command)
	      (setq cur-command 'manued-com-swap-beta))
	     ((eq cur-command 'manued-com-swap-beta)
	      (manued-hilit-one-region colored-pos-pstr lap cur-command)
	      (setq cur-command 'manued-com-swap-gamma))
	     (t
	      (setq hilit-err-occur-pos (manued-get-first-point lap))
	      (error "illegal command, here must be swap command region."))))

	   ;; ]
	   ((manued-command-eq lap manued-r-parenthesis-str)
	    (manued-hilit-one-region colored-pos-pstr lap cur-command)
	    (setq cont nil)) ; return; exit loop

	   (t
	    (setq hilit-err-occur-pos (manued-get-first-point lap))
	    (error "Internal error. I do not know such command."))))))))

;;
;; 終了の括弧がみつからない場合のエラー処理
;;
(defun manued-hilit-can-not-find-end-paren (pstr)
  (setq hilit-err-occur-pos (manued-get-first-point pstr))
  (error (format "hilit-one-level : lack of `%s' of this `%s'"
		 manued-r-parenthesis-str manued-l-parenthesis-str)))
;;
;; hilit-commet
;;
(defun manued-hilit-comment (pstr)
  (let ((lap nil))
    (setq lap (manued-search-nonescaped-command
	       (manued-outof-command-pat) (manued-get-doc-end-point)))
    (if (or (null lap) (not (manued-command-eq lap manued-r-parenthesis-str)))
	(progn
	  (setq hilit-err-occur-pos (manued-get-first-point pstr))
	  (error "Missing r-parenthesis for the end of comment."))
      (progn
	(manued-hilit-one-command lap)
	(manued-hilit-one-region colored-pos-pstr lap 'manued-com-comment)))))

;;
;; 一つの manued コマンド (ex. [, ], /, |, ;) の hilit
;;
(defun manued-hilit-one-command (pstr)
  "一つの真鵺道コマンドを hilit する．"
  (put-text-property (manued-get-first-point pstr)
		     (manued-get-end-point   pstr)
		     'face
		     'manued-command-face))

;;
;; 指定した色で指定範囲を hilit
;;
(defun manued-hilit-one-color (begin-pstr end-pstr color)
  "真鵺道コマンド中の連続した部分を指定した色で hilit する．

hilit a manued region with indicated color-face."
  (put-text-property  (manued-get-end-point   begin-pstr)
		      (manued-get-first-point end-pstr)
                      'face
		      color))

;;
;; ある範囲を色を選択してハイライトする
;; どこまで色を塗ったかを colored-pos-pstr に記録する
;;
(defun manued-hilit-one-region (beg-pstr end-pstr cur-command)
  "hilit a manued command region.
一つの真鵺道コマンドの範囲を指定するとその範囲をハイライトする．"
  (cond ((eq cur-command 'manued-com-delete-first) ; [first/]
	 (manued-hilit-one-color beg-pstr end-pstr 'manued-delete-first-face))
	((eq cur-command 'manued-com-delete-last) ; [/last]
	 (manued-hilit-one-color beg-pstr end-pstr 'manued-delete-last-face))
	((eq cur-command 'manued-com-swap-alpha)  ; [alpha||]
	 (manued-hilit-one-color beg-pstr end-pstr 'manued-swap-alpha-face))
	((eq cur-command 'manued-com-swap-beta)   ; [|beta|]
	 (manued-hilit-one-color beg-pstr end-pstr 'manued-swap-beta-face))
	((eq cur-command 'manued-com-swap-gamma)  ; [||gamma]
	 (manued-hilit-one-color beg-pstr end-pstr 'manued-swap-gamma-face))
	((eq cur-command 'manued-com-comment)     ; [;comment]
	 (manued-hilit-one-color beg-pstr end-pstr 'manued-comment-face))
	(t (error "Unknown manued command and color.")))
  (setq colored-pos-pstr end-pstr))

;;
;; set hilit color
;;
(defun manued-set-hilit-color (color-val-list)
  "hilit 色の設定"
  (let ((color-sym '(manued-delete-first-face
		     manued-delete-last-face
		     manued-swap-alpha-face
		     manued-swap-beta-face
		     manued-swap-gamma-face
		     manued-comment-face
		     manued-command-face))
	(color-val color-val-list))
    ;; (mapcar 'set color-sym color-val) は elisp ではできない．引数は一つ
    (while color-sym
      (let ((face-sym (car color-sym)))
	(make-face face-sym)
	(set-face-foreground face-sym (car color-val))
	(setq color-sym (cdr color-sym))
	(setq color-val (cdr color-val))))))

;;============================================================
;; search manued command
;;============================================================
;;
;; search-nonescaped-command (coms-regpat end-point)
;; エスケープを考えてコマンドをサーチする
;;
;; エスケープの意味は，「エスケープ文字の次の文字は飛ばす」ということ
;; に定義する
;;
(defun manued-search-nonescaped-command (coms-regpat end-point)
  "エスケープを考慮してコマンドをサーチする．
search-coms-regpat : サーチする command 文字の regex パターン
end-point          : どこまで探すか(point)

escape されていないコマンドを探し，みつかったらそのコマンドの
``begin-point end-point コマンド文字列'' のリストを返す．みつからな
かったら nilを返す"
  (catch 'tag
    (while t
      (let ((find-com (manued-search-command coms-regpat end-point)))
	(if (not find-com)
	    (throw 'tag nil)		; コマンドはない
	  ;; escape 文字の場合にはサーチする escape と L-parenthesis
	  ;; との組で与えられている．ex. ~[
	  (let (; (fpos (manued-get-first-point find-com))  ; コマンド群の最初
		(epos (manued-get-end-point   find-com))) ; 終わり
	    (goto-char (manued-get-first-point find-com)) ; コマンド位置へ移動
	    (if (looking-at (regexp-quote manued-escape-str)) ; escape 文字か?
		(progn			; escape str だった
		  (goto-char epos)	; escの後へ移動 ESCPAT^COMPAT
		  (forward-char 1))	; 1文字飛ばす
	      (progn			; escape 文字でなかった
		(goto-char epos)	; 'COMPAT^'
		(throw 'tag find-com)))))))))

;;
;; serach-command (search-coms-regpat end-point)
;; ex.	(manued-search-command "【\\|】\\|/\\|;\\|~"
;;	  (manued-get-doc-end-point))
;;	コマンドのみをサーチする
;;
(defun manued-search-command (search-coms-regpat end-point)
  "manued コマンドを探す. エスケープは考慮しない．
search-coms-regpat : サーチする command 文字の regex パターン
end-point          : どこまで探すか(point)

マッチしたコマンドの (begin-point end-point ``コマンド文字列'') の
リストを返す．みつからなかったら nil を返す．範囲の外から探し始める場
合には re-search-forward の NOERRROR は効かないらしいので対策を講じて
おく．"
  (if (<= end-point (point))
      nil
    (if (re-search-forward search-coms-regpat end-point t)
	(list (match-beginning 0)
	      (match-end 0)
	      (buffer-substring (match-beginning 0) (match-end 0)))
      nil)))

;;
;; search-command-in-hirabun
;;  平文中で真鵺道コマンドを探す
;;
;;  平文中は `~' がコマンドでないにもかかわらず，`~[' はエスケープされ
;;  なくてはならないという特殊な方式にした．これは使い易さのためである．
;;  平文中で考慮しなくてはならない文字を `~' と `[' にするのではなく，
;;  `[' だけにしたいと考えた．
;;
(defun manued-search-nonescaped-command-in-hirabun (end-point)
  "search manued command in normal text region

end-point : where to search.

エスケープされていない平文中の真鵺道コマンドの始まりを探す"
  (catch 'tag
    (while t
      (let ((find-com (manued-search-command
		       (manued-hirabun-command-pat) end-point)))
	(if (not find-com)
	    (throw 'tag nil)		; コマンドはない
	  (if (not (manued-command-eq find-com (manued-escaped-l-paren-pat)))
	      (throw 'tag find-com)))))))

;;------------------------------------------------------------
;; コマンド文字集合
;;------------------------------------------------------------
;; 平文では [ か ~[ を処理する
;;
(defun manued-hirabun-command-pat ()
  "平文から真鵺道に入る場合のコマンド文字集合を得る"
  (concat
   (regexp-quote manued-l-parenthesis-str) "\\|"
   (manued-escaped-l-paren-pat)))

;; ]
(defun manued-outof-command-pat ()
  "真鵺道コマンドから出る場合のコマンド文字集合を得る"
  (concat
   (regexp-quote manued-r-parenthesis-str) 	"\\|"
   (regexp-quote manued-escape-str)))


;; 全コマンド文字
(defun manued-all-command-pat ()
  "真鵺道全コマンド文字集合を得る"
  (concat
   (regexp-quote manued-l-parenthesis-str) 	"\\|"
   (regexp-quote manued-r-parenthesis-str) 	"\\|"
   (regexp-quote manued-delete-str)		"\\|"
   (regexp-quote manued-swap-str)		"\\|"
   (regexp-quote manued-comment-str)		"\\|"
   (regexp-quote manued-escape-str)))

;; ~[ 文字
(defun manued-escaped-l-paren-pat ()
  (concat (regexp-quote manued-escape-str)
	  (regexp-quote manued-l-parenthesis-str)))

;; regrex に使えないが発見した文字のマッチに使う ~[ 文字
(defun manued-escaped-l-paren-str ()
  (concat manued-escape-str manued-l-parenthesis-str))

(defvar manued-ask-if-formatted-buffer-is t
  "* 既に整形済みの buffer が存在した場合に尋ねるかどうか．t で尋ねてくる")

;; 1998年6月27日(土)
;; 先日，知人が死んだ．本日葬式に出た．やりきれぬ．まったく，やりきれん．

;;;============================================================
;;; 新たな manued 整形用バッファの作成
;;;============================================================
;; 新たなバッファの作成
(defun manued-get-format-buffer ()
  "get a formatting buffer for manued.

If no manued buffer, create and return it. Otherwise, ask to the user
overwrite or not. However, if manued-ask-if-formatted-buffer-is is
nil, never ask and override the buffer.

真鵺道の整形用のバッファを作成する．無い場合には作って返す．有る場合に
は消して良いか尋ねる．ただし，manued-ask-if-formatted-buffer-is が nil
の時には尋ねずに作成する．"
  (if (null (get-buffer manued-formatted-buffer-name))
      (get-buffer-create manued-formatted-buffer-name)
	;; 既に存在する
    (if manued-ask-if-formatted-buffer-is
	(let ((prompt (format "buffer %s is already exist. clear? "
			      manued-formatted-buffer-name)))
	  (if (y-or-n-p prompt)
	      (let ((curbuf (current-buffer)))
		(switch-to-buffer manued-formatted-buffer-name)
		(kill-buffer manued-formatted-buffer-name)
		(switch-to-buffer curbuf)
		(get-buffer-create manued-formatted-buffer-name))
	    nil)))))

;;============================================================
;; pretty print control
;;============================================================
(defun manued-set-pretty-print-off ()
  "set manued pretty print off"
  (interactive)
  (setq manued-pretty-print-on-p nil))

(defun manued-set-pretty-print-on ()
  "set manued pretty print on"
  (interactive)
  (setq manued-pretty-print-on-p t))

;;============================================================
;; show : 整形コマンド
;;============================================================
;;
;; show newer
;;
(defvar manued-show-newer-p nil)
(defun manued-show-newer-in-manued-buffer ()
  "Show revised document from current manued document to another buffer.
現在のバッファの真鵺道文書の変更後の文書を他のバッファに表示する．"
  (interactive)
  (manued-show-in-manued-buffer t manued-pretty-print-on-p))

;;
;; show newer document with region
;;
(defun manued-show-newer-region (b e)
  "Show newer version with region.
リージョンの範囲を整形して新しい文書を取り出す"
  (interactive "r")
  (setq manued-show-newer-p t)
  ;; (dbg (format "b = %d, e = %d" b e))
  (manued-show-region b e))

;;
;; show older
;;
(defun manued-show-older-in-manued-buffer ()
  "Show original document from current manued document to another buffer.
文章中の真鵺道コマンドの変更前の文書を他のバッファに表示する．"
  (interactive)
  (manued-show-in-manued-buffer nil manued-pretty-print-on-p))

;;
;; show older document with region
;;
(defun manued-show-older-region (b e)
  "Show older version with region.
リージョンの範囲を整形して古い文書を取り出す"
  (interactive "r")
  (setq manued-show-newer-p nil)
  (manued-show-region b e))

;;
;; show revised document at another buffer
;;	他のバッファを作り，そこに内容をコピーして整形する
;;
(defun manued-show-in-manued-buffer (show-newer-p pretty-print-p)
  "Show processed manued document to another buffer.

When show-newer-p is t, newer document is shown. Otherwise, older
document is shown.

文章中の真鵺道コマンド中の元文書を他のバッファに表示する．
show-newer-p が t なら新しい方を表示し，nil なら古い方を表示する．"
  (let ((formatbuf (manued-get-format-buffer)))
    (if formatbuf
	(let ((orgbuf (current-buffer)))	; 現在の buffer
	  (pop-to-buffer formatbuf)
	  (insert-buffer orgbuf)
	  (setq manued-show-newer-p      show-newer-p)
	  (setq manued-pretty-print-on-p pretty-print-p)
	  (manued-show-buffer)))))

;;
;; 現在のバッファの真鵺道コマンドの整形を行う
;;
(defun manued-show-buffer ()
  "現在のバッファの真鵺道コマンドを整形する．
現在の manued-show-newer-p が示す部分を取り出す．"
  (let ((replace-err-occur-pos nil))
    (condition-case err-message
	(save-excursion
	  (manued-init-vars)
	  (manued-show-region (manued-get-doc-begin-point)
			      (manued-get-doc-end-point)))
      (error				; error handling
       (if replace-err-occur-pos
	   (goto-char replace-err-occur-pos))
       (error (format "Error! : %s" err-message))))))

;;
;; 現在のバッファの region で指定された範囲の真鵺道コマンドの整形を行う
;;
(defun manued-show-region (b e)
  "現在のバッファの真鵺道コマンドを整形する．
現在の manued-show-newer-p が示す部分を取り出す．"
  (goto-char e)
  (let ((region-end-marker (point-marker))) ; marker of the end of the region
    (goto-char b)
    (while (manued-replace-manuedexp region-end-marker))
    (goto-char (marker-position region-end-marker))
    (set-marker region-end-marker nil)))

;;
;; replace-toplevel
;;
(defun manued-replace-manuedexp (region-end-marker)
  "真鵺道文書の平文中のコマンドを処理する．"
  (let ((cont t))
    (while cont
      (let ((lap
	     (manued-search-command (manued-hirabun-command-pat)
				    (marker-position region-end-marker))))
	(cond
	 ((eq lap nil)			; lap is nil ... command is not found.
	  (setq cont nil))		; 全て処理した: exit loop

	 ;; ~[ 平文中のエスケープ括弧の処理
	 ((string-equal (manued-escaped-l-paren-str)
			(manued-get-command-str lap))
	  (let ((m (make-marker)))
	    (set-marker m (manued-get-end-point lap)) ; ~[^ の終わりにマーク
	    (manued-proc-escape (manued-get-first-point lap)
				(manued-get-end-point   lap))
	    (goto-char (marker-position m))
	    (set-marker m nil)))

	 ;; [ 真鵺道コマンドの処理
	 (t
	  (manued-replace-manued-term lap region-end-marker)))))))

;;
;; まず最内の [] をみつけるそしてその最内真鵺道コマンドから再帰的に処理
;; 再帰的に処理をしても文書の前の方で検出した point は変化しない
;;
;; lap = LookAhead-Pstr
;;
(defun manued-replace-manued-term (beg-lap region-end-marker)
  (let ((cont t)
	(lap nil)			; lookahead-pstr
	(swap-pstr-list   '())		; swap   記号のリスト
	(delete-pstr-list '())		; delete 記号のリスト
	)
    (while cont
      (setq lap (manued-search-nonescaped-command
		 (manued-all-command-pat) (marker-position region-end-marker)))
      (if (null lap)
	  ;; Error. No command is found. At least, `]' must be found here.
	  (progn
	    (manued-replace-can-not-find-end-paren beg-lap)
	    (setq cont nil))
	(cond
	 ;; ; comment
	 ((manued-command-eq lap manued-comment-str)
	  (let ((comment-pstr lap))
	    (setq lap (manued-search-nonescaped-command
		       (manued-outof-command-pat)
		       (marker-position region-end-marker)))
	    (if (not (null lap))
		(progn
		  (manued-replace-one-term swap-pstr-list delete-pstr-list
					   beg-lap lap comment-pstr)
		  (setq cont nil))
	      (progn
		(manued-replace-can-not-find-end-paren beg-lap)
		(setq cont nil)))))
	 ;; [, recursion
	 ((manued-command-eq lap manued-l-parenthesis-str)
	  (manued-replace-manued-term lap region-end-marker))
	 ;; / delete
	 ((manued-command-eq lap manued-delete-str)
	  (setq delete-pstr-list (cons lap delete-pstr-list)))
	 ;; | swap
	 ((manued-command-eq lap manued-swap-str)
	  (setq swap-pstr-list (cons lap swap-pstr-list)))
	 ;; ]
	 ((manued-command-eq lap manued-r-parenthesis-str)
	  (manued-replace-one-term swap-pstr-list delete-pstr-list
				   beg-lap lap nil)
	  (setq cont nil))		; return; exit loop
	 ;; error
	 (t
	  (error "Internal error. I do not know such replace command.")))))))

;;
;; コマンドの整合性のチェック
;;   beg-lap はエラーの発生場所を示すため
;;
(defun manued-check-command (swap-symcount delete-symcount beg-lap)
  (catch 'tag
    (let ((permitted-occur-num-list	; 許される組合せ
	   '((0 0)			; []
	     (0 1)			; [/]
	     (2 0))))			; [||]
      (while (not (null permitted-occur-num-list))
	(let ((comb (car permitted-occur-num-list)))
	  (if (and (= swap-symcount (car comb))
		   (= delete-symcount (car (cdr comb))))
	      (throw 'tag t))
	  (setq permitted-occur-num-list (cdr permitted-occur-num-list))))
      (goto-char (manued-get-first-point beg-lap))
      (if (> swap-symcount 0)
	  (error (format "Illegal swap command. %s can appear only 0/2 times."
			 manued-swap-str))
	(error (format "Illegal delete command. %s can appear only 0/1 times."
		       manued-delete-str))))))


;;
;; コマンドによって整形コマンドを呼び出す
;;
(defun manued-replace-one-term (swap-pstr-list delete-pstr-list
					       beg-lap end-lap comment-psr)
  (let ((swap-symcount   (length swap-pstr-list))
	(delete-symcount (length delete-pstr-list)))
    ;; consistency check
    (manued-check-command swap-symcount delete-symcount beg-lap)
    ;; replace
    (cond
     ((eq swap-symcount 2)
      (manued-replace-one-swap-term
       swap-pstr-list beg-lap end-lap comment-psr)
      )
     ((eq delete-symcount 1)
      (manued-replace-one-delete-term
       delete-pstr-list beg-lap end-lap comment-psr)
      )
     (t
      (manued-replace-one-null-term beg-lap end-lap comment-psr)))))

;;
;; get pretty print strings
;;
(defun manued-get-pretty-print-str (format-str arg-str)
  ;; if there is args, output anyway
  (let ((res ""))
    (if (not (null arg-str))
	(setq res (format format-str arg-str))
      (if manued-pretty-print-null-comment-out-p
	  (setq res (format format-str "")))
      )
    res))

;;
;; swap コマンドを処理する
;; 	[alpha|beta|gamma;comment]
;; アルゴリズムの概要
;; 消して insert することで入れ換えを行う．insert の後にポイントが来る
;; のでその場でマークすると範囲の最後がわかる．そこで escape を処理し，
;; 最後に移動する．
;;
(defun manued-replace-one-swap-term (swap-pstr-list
				     beg-lap end-lap comment-psr)
  (let ((end-marker  (make-marker))
	(beg-alpha   (manued-get-end-point    beg-lap))
	(end-alpha   (manued-get-first-point (car (cdr swap-pstr-list))))
	(beg-beta    (manued-get-end-point   (car (cdr swap-pstr-list))))
	(end-beta    (manued-get-first-point (car  swap-pstr-list)))
	(beg-gamma   (manued-get-end-point   (car  swap-pstr-list)))
	(end-gamma   nil)
	(beg-comment nil)
	(end-comment nil))
    (if (not (null comment-psr))
	(progn
	  (setq end-gamma   (manued-get-first-point comment-psr))
	  (setq beg-comment (manued-get-end-point   comment-psr))
	  (setq end-comment (manued-get-first-point end-lap)))
      (setq end-gamma (manued-get-first-point end-lap)))
    (let ((alpha  (buffer-substring beg-alpha end-alpha))
	  (beta   (buffer-substring beg-beta  end-beta))
	  (gamma  (buffer-substring beg-gamma end-gamma))
	  (comment nil))
      (if (not (null beg-comment))	; wenn es gibt ein comment.
	  (setq comment (buffer-substring beg-comment end-comment)))
      (goto-char (manued-get-first-point beg-lap))
      ;; delete manued command
      (delete-region (manued-get-first-point beg-lap)
		     (manued-get-end-point   end-lap))
      ;; insert the result
      (let ((erst    "")
	    (zweite  "")
	    (dritter ""))
	(if manued-show-newer-p
	    (progn
	      (setq erst    gamma)
	      (setq zweite  beta)
	      (setq dritter alpha))
	  (progn
	    (setq erst    alpha)
	    (setq zweite  beta)
	    (setq dritter gamma)))
	(if (not manued-pretty-print-on-p)
	    ;; no pretty print
	    (insert (concat erst zweite dritter))
	  ;; pretty print
	  (let ((e-str "")
		(z-str "")
		(d-str "")
		(v-str ""))
	    (setq e-str
		  (manued-get-pretty-print-str
		   (nth 0 manued-pretty-print-format-swap-list)
		   erst))
	    (setq z-str
		  (manued-get-pretty-print-str
		   (nth 1 manued-pretty-print-format-swap-list)
		   zweite))
	    (setq d-str
		  (manued-get-pretty-print-str
		   (nth 2 manued-pretty-print-format-swap-list)
		   dritter))
	    (setq v-str
		  (manued-get-pretty-print-str
		   (nth 3 manued-pretty-print-format-swap-list)
		   comment))
	    (insert (concat e-str z-str d-str v-str))))
	(set-marker end-marker (point))
	(manued-proc-escape (manued-get-first-point beg-lap) (point))
	(goto-char (marker-position end-marker))
	(set-marker end-marker nil)))))
;;
;; delete コマンドを処理する
;;   Escape 処理のアルゴリズムは swap と同様
;;
(defun manued-replace-one-delete-term (delete-pstr-list beg-lap end-lap
							comment-psr)
  (let ((end-marker (make-marker))
	(A-part-str  nil)
	(B-part-str  nil)
	(C-part-str  nil)
	(insert-part-str  nil)
	(delete-part-str  nil)
	(comment-part-str nil))
    ;; [^A^/B;C]
    (setq A-part-str (buffer-substring
		      (manued-get-end-point beg-lap)
		      (manued-get-first-point (car delete-pstr-list))))
    (if comment-psr
	(progn
	  ;; [A/^B^;C]
	  (setq B-part-str (buffer-substring
			    (manued-get-end-point (car delete-pstr-list))
			    (manued-get-first-point comment-psr)))
	  ;; [A/B;^C^]
	  (setq C-part-str (buffer-substring
			    (manued-get-end-point comment-psr)
			    (manued-get-first-point end-lap))))
      (progn
	;; [A/^B^]
	(setq B-part-str (buffer-substring
			  (manued-get-end-point (car delete-pstr-list))
			  (manued-get-first-point end-lap)))
	;; [A/B] ... keine C Teil
	(setq C-part-str nil)))
    ;; get first region?  : thanks for KAWAMURA
    ;;	true case 1 : if `show older' and `older first'
    ;;	     case 2 : if `show newer' and `newer first'
    (if (or (and (not manued-show-newer-p) manued-is-order-older-first)
	    (and  manued-show-newer-p     (not manued-is-order-older-first)))
	(progn
	  (setq insert-part-str  A-part-str)
	  (setq delete-part-str  B-part-str)
	  (setq comment-part-str C-part-str))
      ;; or last region
      (progn
	(setq insert-part-str  B-part-str)
	(setq delete-part-str  A-part-str)
	(setq comment-part-str C-part-str)))

    ;; delete manued command
    (delete-region (manued-get-first-point beg-lap)
		   (manued-get-end-point   end-lap))

    ;; insert the result
    (if (not manued-pretty-print-on-p)
	;; no pretty print
	(insert insert-part-str)
      ;; do pretty print
      (let ((i-str "")
	    (d-str "")
	    (c-str ""))
	(setq i-str
	      (manued-get-pretty-print-str
	       (nth 0 manued-pretty-print-format-delete-list)
	       insert-part-str))
	(setq d-str
	      (manued-get-pretty-print-str
	       (nth 1 manued-pretty-print-format-delete-list)
	       delete-part-str))
	(setq c-str
	      (manued-get-pretty-print-str
	       (nth 2 manued-pretty-print-format-delete-list)
	       comment-part-str))
	(insert (concat i-str d-str c-str))))
    (set-marker end-marker (point))
    (manued-proc-escape (manued-get-first-point beg-lap) (point))
    (goto-char (marker-position end-marker))
    (set-marker end-marker nil)))

;;
;; null コマンドを処理する
;;	null コマンドは消去してしまって良いだろう
;;
(defun manued-replace-one-null-term (beg-lap end-lap comment-psr)
  (let ((end-marker (make-marker)))
    (set-marker end-marker (manued-get-end-point end-lap))
    (delete-region (manued-get-first-point beg-lap)
		   (manued-get-end-point   end-lap))
    (goto-char (marker-position end-marker))
    (set-marker end-marker nil)))

;;
;; proc-escape :
;; 	begin-point から end-point までの間で escape を処理する
;;
(defun manued-proc-escape (begin-point end-point)
  "process escape
  begin-point end-point までに存在するエスケープの処理"
  (goto-char end-point)
  (let ((m-end (point-marker))		; 編集中に変化するので最後に印
	(m-cont nil))
    (goto-char begin-point)
    (let ((esc-pstr t))
      (while esc-pstr			; 範囲内で escape 文字がある限り
	(setq esc-pstr (manued-search-command
			(regexp-quote manued-escape-str)
			(marker-position m-end)))
	(if (not (null esc-pstr))
	    (progn
	      (goto-char (manued-get-end-point esc-pstr))
	      (setq m-cont (point-marker)) ; esc の最後に mark
	      (delete-region (manued-get-first-point esc-pstr) ; del esc str
			     (manued-get-end-point   esc-pstr))
	      (goto-char (marker-position m-cont)) ; esc の直後に移動
	      (set-marker m-cont nil)
	      (forward-char 1))		; esc の次の文字を飛ばす
	  ;; else (null esc-pstr) なら終了
	  )))
    (set-marker m-end nil)))


;;
;; 終了の括弧がみつからない場合のエラー処理
;;
(defun manued-replace-can-not-find-end-paren (start-ptr)
  (setq replace-err-occur-pos (manued-get-first-point start-ptr))
  (error (format "in replace : lack of `%s' of this `%s'"
		 manued-r-parenthesis-str manued-l-parenthesis-str)))


;;============================================================
;; editting command
;;============================================================
;; insert delete command
;;   with comment or not
;;------------------------------
(defun manued-insert-delete-command-toggle-comment (b e)
  "delete command の挿入時にコメント挿入をデフォルトと逆にする
manued-is-delete-command-with-comment-on を逆の状態にして
manued-insert-delete-command を呼ぶ．"
  (interactive "r")
  (let ((manued-is-delete-command-with-comment-on ; dynamic binding!
	 (not manued-is-delete-command-with-comment-on)))
    (manued-insert-delete-command b e)))

;;
;; insert delete command
;;
(defun manued-insert-delete-command (b e)
  "insert delete command"
  (interactive "r")
  (let ((imark))
    (goto-char e)			; 後ろから処理する
    (if manued-is-order-older-first	; [region/]
	(progn
	  (insert manued-delete-str)	; /
	  (setq imark (point-marker))	; /^
	  (if manued-is-delete-command-with-comment-on
	      (insert manued-comment-str)))) ; /^;
    (insert manued-r-parenthesis-str)	; /^;] or /^]
    (goto-char b)			; 前方へ
    (insert manued-l-parenthesis-str)	; [
    (if (not manued-is-order-older-first) ; [/region]
	(progn
	  (setq imark (point-marker))	; [^
	  (insert manued-delete-str)
	  (if manued-is-delete-command-with-comment-on
	      (insert manued-comment-str)))) ; [^/ or [
    (goto-char (marker-position imark))
    (set-marker imark nil)))		; for GC

;;------------------------------
;; insert swap command
;;   with comment or not
;;------------------------------
(defun manued-insert-swap-command-toggle-comment (b e)
  "swap command の挿入時にコメント挿入をデフォルトと逆にする
manued-is-swap-command-with-comment-on を逆の状態にして
manued-insert-swap-command を呼ぶ．"
  (interactive "r")
  (let ((manued-is-swap-command-with-comment-on
	 (not manued-is-swap-command-with-comment-on)))
    (manued-insert-swap-command b e)))


;;
;; insert swap command
;;
(defun manued-insert-swap-command (b e)
  "insert swap command"
  (interactive "r")
  (let ((imark))
    (goto-char e)			; 後ろから処理する [region||]
    (insert manued-swap-str)		; |
    (setq imark (point-marker))		; |^|
    (insert manued-swap-str)		; |^|
    (if manued-is-swap-command-with-comment-on
	(insert manued-comment-str))	; ||^;
    (insert manued-r-parenthesis-str)	; ||^;] or ||^]
    (goto-char b)			; 前方へ
    (insert manued-l-parenthesis-str)	; [
    (goto-char (marker-position imark))
    (set-marker imark nil)))		; for GC

;;------------------------------
;; insert manued comment
;;    ある変数によって引数の違う関数を呼ぶのはどうするのか
;;------------------------------
;(defun manued-insert-comment (p)
;  (interactive "d")
;  (manued-insert-comment-at-point p))
;(defun manued-insert-comment (b e)
;  (interactive "r")
;  (manued-insert-comment-region b e))

;;
;; insert manued comment
;;
(defun manued-insert-comment-at-point (p)
  "insert manued commnet at this point"
  (interactive "d")
  (goto-char p)
  (let ((imark))
    (insert manued-l-parenthesis-str)
    (insert manued-comment-str)
    (setq imark (point-marker))
    (insert manued-r-parenthesis-str)
    (goto-char (marker-position imark))
    (set-marker imark nil)))

;;
;; insert manued comment with region 1998年8月11日(火)
;;
(defun manued-insert-comment-region (b e)
  "insert manued commnet with region"
  (interactive "r")
  (let ((imark) (eq-begin-and-end (= b e)))
    (setq imark (point-marker))
    (goto-char e)
    (insert manued-r-parenthesis-str)
    (goto-char b)
    (insert manued-l-parenthesis-str)
    (insert manued-comment-str)
    (goto-char (marker-position imark))
    ;; mark した場所に挿入した場合には [; の分を動いてすぐ入力できるようにする
    (if eq-begin-and-end
	(goto-char (+ (point)
		      (length manued-l-parenthesis-str)
		      (length manued-comment-str))))
    (set-marker imark nil)))

;;============================================================
;; moving command
;;============================================================
(defun manued-next-l-parenthesis (p)
  "goto next manued L-parenthesis"
  (interactive "d")
  (goto-char p)
  (let ((matchpos))			; (nowpos p) deleteme
    (setq matchpos
	  (re-search-forward
	   (format "[^%s]%s"
		   (regexp-quote manued-escape-str)
		   (regexp-quote manued-l-parenthesis-str))
	   (manued-get-doc-end-point) t))
    (if (null matchpos)			; non exist
	(progn
	  (message "manued: no more next manued L-parenthesis.")
	  (beep))
      (backward-char 1))))

(defun manued-previous-l-parenthesis (p)
  "goto previous manued l parenthesis"
  (interactive "d")
  (goto-char p)
  (let ((matchpos))			; (nowpos p) deleteme
    (setq matchpos
	  (re-search-backward
	   (format "[^%s]%s"
		   (regexp-quote manued-escape-str)
		   (regexp-quote manued-l-parenthesis-str))
	   (manued-get-doc-begin-point) t))
    (if (null matchpos)			; non exist
	(progn
	  (message "manued: no more previous manued L-parenthesis.")
	  (beep))
      (backward-char -1))))


(defun manued-eval-last-manuexp (p)
  "Eval last manued-command.
Evauate last manued command from now point. Same as eval-last-sexp.
When argment is setted, reciprocal mode is used. Ex. when now mode is
show-newer, then evaluating with show-older. However this command
search backword and using first matched l-parenthesis-str, this
command mistakes interpretation for the command.

Ex. `[A/B; [a/hello]' must be `B' in manued fashion, may evaluated to
    `[A/B; hello'

直前の一つの真鵺道コマンドの評価を行う．eval-last-sexp と同様．引数を
与えると現在が newer ならば older を，というように逆の動作をする．ただ
し，後方から最初にマッチした manued-l-parenthesis-str を探すので，コメ
ント内部に真鵺道コマンドがある場合には正しく処理されないかもしれない．
たとえば上の例のような場合がある．"
  (interactive "p")
  (save-excursion
    (let ((is-newer))
      (if (> p 1)
	  (setq is-newer (not manued-is-now-hilit-newer))
	(setq is-newer manued-is-now-hilit-newer))
      (let ((last-manuexp-region (manued-lastexp-region)))
	(if (null last-manuexp-region)
	    (progn
	      (error "manued-eval-last-manuexp, cannot find last manuexp."))
	  (progn
	    (goto-char (car last-manuexp-region))
	    (if is-newer
		(manued-show-newer-region (car  last-manuexp-region)
					  (car (cdr last-manuexp-region)))
	      (manued-show-older-region (car  last-manuexp-region)
					   (car (cdr last-manuexp-region))))))))))

;;
;; get last region
;;
(defun manued-lastexp-region ()
  (let ((end-pstr nil) (beg-pstr nil) (cont t))
    ;; find last ]
    (while cont
      (let ((cur-pstr (manued-search-last-command-backword-pstr)))
	(cond
	 ((manued-command-eq cur-pstr manued-r-parenthesis-str)
	  (setq end-pstr cur-pstr)
	  (setq cont nil))
	 ((manued-command-eq cur-pstr manued-l-parenthesis-str)
	  t)				; ignore
	 ((eq cur-pstr nil)
	  (error "Can not find last manued exp."))
	 (t
	  (error "Internal error. manued-lastexp-region.1")))))
    ;; find '[' which corresponding last `]'
    (let ((paren-level 1) (cont t))
      (while cont
	(let ((cur-pstr (manued-search-last-command-backword-pstr)))
	  (cond
	   ((manued-command-eq cur-pstr manued-r-parenthesis-str)
	    (setq paren-level (1+ paren-level)))
	   ((manued-command-eq cur-pstr manued-l-parenthesis-str)
	    (setq paren-level (1- paren-level))
	    (if (= paren-level 0)
		(progn
		  (setq beg-pstr cur-pstr)
		  (setq cont nil))))
	   ((eq cur-pstr nil)
	    (error "Can not find paren corresponding to last manued exp."))
	   (t
	    (error "Internal error. manued-lastexp-region.2"))))))
    (list (manued-get-first-point beg-pstr)
	  (manued-get-end-point   end-pstr))))

;;
;; escape されていない括弧を探す
;;
(defun manued-lastexp-detect-pat ()
  (concat
   (regexp-quote manued-l-parenthesis-str) 				"\\|"
   (regexp-quote manued-r-parenthesis-str)))

;;
;; escape されているものは探さない
;;
(defun manued-lastexp-non-detect-pat ()
  (concat
   (regexp-quote (concat manued-escape-str manued-l-parenthesis-str))	"\\|"
   (regexp-quote (concat manued-escape-str manued-r-parenthesis-str))))

;;
;; 後方から前方に def[LR]parenthesis のみを探索する
;;
;; backword で regex に選択を書いても最長一致でないようである．マニュ
;; アルによると，re-search-backword は re-search-forward の完全なミラー
;; ではないということだ．うーむ．
;;
(defun manued-search-last-command-backword-pstr ()
  (let ((ret-pstr nil) (cont t) (found nil))
    (while cont
      (if (null (re-search-backward (manued-lastexp-detect-pat)
				    (manued-get-doc-begin-point) t))
	  (setq cont nil)		; re-search-backward に失敗
	(progn
	  (setq ret-pstr
		(list (match-beginning 0)
		      (match-end 0)
		      (buffer-substring (match-beginning 0) (match-end 0))))
	  (if (< 0 (- (point) (length manued-escape-str)))
	      (progn
		(goto-char (- (point) (length manued-escape-str)))
		(if (not (looking-at (manued-lastexp-non-detect-pat)))
		    (progn
		      (setq found t)	; found
		      (setq cont nil)
		      ;; 孤立括弧がみつかったなら戻っておく
		      (goto-char (+ (point) (length manued-escape-str))))
		  ;; この行では ~]か ~[ なので無視して次の while loop を回る
		  ))
	    (progn
	      (setq found t)
	      (setq cont nil))))))	; これ以上前にはいけないので発見
    (if found
	ret-pstr			;発見している場合
      nil)))

;;============================================================
;; initialize manued
;;	initialize variables and get defcommands.
;;============================================================
(defun manued-init-vars ()
  "Initialize variables.
	search and get document begin point and end point.
	真鵺道文書中から必要な情報を取り出し，初期化する．"
  (save-excursion
    ;;(setq manued-doc-begin-point nil)
    ;;(setq manued-doc-end-point   nil)
    (manued-get-doc-begin-point)
    (manued-get-doc-end-point)
    ;; defcommandを探し，値をセットする
    (manued-search-set-defcommands)
    ;; color mode が使えないようなら off にする
    (if (not window-system)
	;; not window-system
	(progn
	  (if manued-use-color-hilit	; この時はhilitは強制的にoff
	      (progn
		(message
		 "manued: This window may not be able to use color. Color mode is off.")
		(setq manued-use-color-hilit nil)))))
    ;; re-initialize color face
    ))

;;
;; if use-color 'follow-font-lock-mode, according to font-lock-mode
;;   @return when t use color, nil not use
;;
(defun manued-guess-color-mode ()
  (cond ((eq manued-use-color-hilit 'follow-font-lock-mode)
	 (cond (manued-xemacs-p font-lock-mode)		; xemacs
	       (t			; mule
		;;(if (boundp 'font-lock-mode)
		;; font-lock-mode	; value
		;;  nil))))
		;; mule, emacs20 ではfont-lock-modeと共存できていない．
		t)))
	(t manued-use-color-hilit)))	; follow でなければこの値を返す

;;============================================================
;; manued-minor-mode
;;	Manued has the minor-mode only.
;;============================================================
;; menu-bar
;;	真鵺道メニュー
;;	ref. mew.el 	 by Kazu Yamamoto
;;	     easymenu.el by rms.
;;------------------------------------------------------------
(if (or manued-xemacs-p (string< "20" emacs-version)) (require 'easymenu))
(defvar manued-mode-menu-bar-map nil)
(defconst manued-minor-mode-menu-spec
  '("Manued"
    ["Hilit revised  part"	manued-hilit-newer	t]
    ["Hilit original part"	manued-hilit-older	t]
    "---"
    ("Extract document"
     ["Get revised  document in manued buf"
      manued-show-newer-in-manued-buffer t]
     ["Get original document in manued buf"
      manued-show-older-in-manued-buffer t]
     ["Get revised  document from region"
      manued-show-newer-region	t]
     ["Get original document from region"
      manued-show-older-region	t]
     ["set pretty print on"
      manued-set-pretty-print-on t]
     ["set pretty print off"
      manued-set-pretty-print-off t])
    ["Eval last manuedexp"		manued-eval-last-manuexp t]
    "---"
    ("Insert command"
     ["Swap    region"               	manued-insert-swap-command t]
     ["Delete  region"               	manued-insert-delete-command t]
     ["Comment region"              	manued-insert-comment-region t]
     ["Header"              		manued-insert-header	t])
    "---"
    ["Search next"              	manued-next-l-parenthesis t]
    ["Search previous"          	manued-previous-l-parenthesis t]
    ["Show version"          		manued-show-version t]))


;;------------------------------
;; 真鵺道の minor mode keymap
;;------------------------------
(defvar manued-minor-mode-map nil
  "* keymap of manued. minor mode.
   真鵺道のキーマップ:
\\<manued-minor-mode-map>")

(if (null manued-minor-mode-map)
    (progn
      (setq manued-minor-mode-map (make-sparse-keymap))
      ;;(define-key manued-minor-mode-map
      ;; manued-mode-menu-bar-map) deleteme

      (define-key manued-minor-mode-map "\C-c\C-m\C-d"
	'manued-insert-delete-command)
      (define-key manued-minor-mode-map "\C-c\C-md"
	'manued-insert-delete-command-toggle-comment)

      (define-key manued-minor-mode-map "\C-c\C-m\C-s"
	'manued-insert-swap-command)
      (define-key manued-minor-mode-map "\C-c\C-ms"
	'manued-insert-swap-command-toggle-comment)

      (define-key manued-minor-mode-map "\C-l"
	'manued-recenter-hilit)

      (define-key manued-minor-mode-map "\C-c\C-m\C-c"
	'manued-insert-comment-region)

      (define-key manued-minor-mode-map "\M-n"
	'manued-next-l-parenthesis)
      (define-key manued-minor-mode-map "\M-p"
	'manued-previous-l-parenthesis)

      (define-key manued-minor-mode-map "\C-c\C-m\C-e"
	'manued-eval-last-manuexp)
      ;; other definitions

      ;;
      (easy-menu-define
       manued-minor-mode-menu
       manued-minor-mode-map
       "Manued : a proofreading method."
       manued-minor-mode-menu-spec)))


;;------------------------------------------------------------
;; syntax, abbrev tables
;;------------------------------------------------------------
(defvar manued-mode-syntax-table text-mode-syntax-table
  "* syntax table of manued mode : default is `text-mode-syntax-table'
真鵺道モードの syntax table : default 値は `text-mode-syntax-table'")

(defvar manued-mode-abbrev-table text-mode-abbrev-table
  "* abbrev table of manued mode : default is `text-mode-abbrev-table'
真鵺道モードの abbrev table : default 値は `text-mode-abbrev-table'")

;;------------------------------------------------------------
;; 過去のバージョンとの差分を吸収する
;;	しかし今は打つ手がないな
;;	ヘッダがないのかバージョンが古いのかはどうしようもない気がする
;;------------------------------------------------------------
(defun manued-dispatch-for-old-version ()
  (progn
    ;; swap-str を delete-str と間違えていたバージョン用
    ;; ここが string= でなく match なのは部分的に同じ場合に問題が発生
    ;; するかと考えたため ex. defparentheses ( ), defswap )| の場合
    ;; (a/b)の次に | が平文中に出た場合に困る．と思うが試してみよう
    (if (string-match manued-swap-str manued-delete-str)
    ;; (if (string-equal manued-swap-str manued-delete-str)
	(if (y-or-n-p
	     "Buffer is edited by old manued.el. Change swap-str defs?")
	    (progn
	      (setq manued-swap-str "|")
	      (setq manued-delete-str "/"))))
    ;; defLparenthesis, defRparenthesis が存在する場合に警告する
    (goto-char (manued-get-doc-begin-point))
    (if (re-search-forward "def[LR]parenthesis" nil t)
	(progn
	  (ding)
	  (message
	   "def[LR]parenthesis is supported but obsolete, use defparentheses")
	  (sit-for 1)))))
;; version 比較 (string< "1.0.0" "1.0.10") の場合には失敗する．．．

;;============================================================
;; 真鵺道 minor モードに入る．
;;============================================================
(defvar manued-minor-mode nil)		; 真鵺道 minor mode にいるかどうか
(defvar manued-pushd-menubar nil)	; 元の Menubar を保存する
(defalias 'manued-mode 'manued-minor-mode)
(defun manued-minor-mode (&optional arg)
  "Toggle Manued minor mode.
With arg, turn Manued minor mode on if arg is positive, off otherwise.
See the command `manued-mode' for more information on this mode.

Manued-minor-mode (In English)


emphasis original document.		\\[manued-hilit-older]
emphasis proofreaded document.		\\[manued-hilit-newer]
re-hilit				\\[manued-hilit]
show the fixed document in other buffer	\\[manued-show-older-in-manued-buffer]
show the original document in other buffer	\\[manued-show-newer-in-manued-buffer]
set revised document without pretty print	\\[manued-set-pretty-print-off]
set revised document with pretty print	\\[manued-set-pretty-print-on]
insert manued delete command		\\[manued-insert-delete-command]
insert manued swap   command		\\[manued-insert-swap-command]

insert comment command			\\[manued-insert-comment]
eval last manued command		\\[manued-eval-last-manuexp]

Manued-minor-mode (In Japanese)
マイナーモード

修正前の文書のハイライト		\\[manued-hilit-older]
修正後の文書のハイライト		\\[manued-hilit-newer]
再ハイライト			\\[manued-hilit]
修正前の文書を別のバッファに表示	\\[manued-show-older-in-manued-buffer]
修正後の文書を別のバッファに表示	\\[manued-show-newer-in-manued-buffer]
修正前の文書をpretty printスタイルで表示	\\[manued-set-pretty-print-on]
修正前の文書を通常のスタイルで表示	\\[manued-set-pretty-print-off]

真鵺道 delete コマンドの入力		\\[manued-insert-delete-command]
真鵺道 swap コマンドの入力		\\[manued-insert-swap-command]
真鵺道 comment の入力			\\[manued-insert-comment]
直前の真鵺道コマンドの評価	       	\\[manued-eval-last-manuexp]

Special Commands:

\\{manued-minor-mode-map}
"

  (interactive "P")
  (make-variable-buffer-local 'manued-minor-mode)
  (setq manued-minor-mode
	(if (null arg) (not manued-minor-mode) ; toggle
	  (> (prefix-numeric-value arg) 0)))
  (if manued-minor-mode
      (progn
	(manued-init-vars)
	(run-hooks 'manued-minor-mode-hook)
	(manued-search-and-insert-header)
	(manued-add-menu-bar)		; add manued menu to manu bar
	(manued-hilit))			; hilit
    ;;
    (if window-system
	(progn
	  (manued-delele-menu-bar)	  ; and menu bar
	  ))))

;;
;; add menu bar
;; どうやら，xemacsでないEmacsではeasymenuがadd, deleteまでみてくれるようだ
;;
(defun manued-add-menu-bar ()
  (if manued-xemacs-p
      (progn
	(setq manued-pushd-menubar current-menubar)
	(set-buffer-menubar current-menubar) ; for buffer local
	(add-submenu nil manued-minor-mode-menu-spec))
    ;; nothing to do in non xemacs enviroment
    ()
    ))

;;
;; delete menu bar
;;
(defun manued-delele-menu-bar ()
  (if manued-xemacs-p
      (set-buffer-menubar manued-pushd-menubar)
    ;; nothing to do in non xemacs enviroment
    ()
    ))

;;
;; minor mode alist
;;
(or (assq 'manued-minor-mode minor-mode-alist)
    (setq minor-mode-alist
	  (cons '(manued-minor-mode " Manued") minor-mode-alist)))

;;
;; minor mode keymap alist
;;
(or (assq 'manued-minor-mode minor-mode-map-alist)
    (setq minor-mode-map-alist
	  (cons (cons 'manued-minor-mode manued-minor-mode-map)
		minor-mode-map-alist)))
;;
(provide 'manued)
;;; manued.el ends here
