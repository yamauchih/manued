;;; manued.el --- a minor mode of manued proofreading method.
;;
;; Author: Hitoshi Yamauchi
;; Maintainer: Hitoshi Yamauchi
;; Created: 16 Jan 1998
;; Keywords: proofreading, docs
;;
;; Contributors: Atusi Maeda
;;	          Stefan Monnier (0.9.1)
;;	          Mikio Nakajima (0.9.3)
;;	          Takao Kawamura (0.9.3)
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Manued stands for MANUscripting EDitor.
;;
;; Original idea of manued:
;;	Ikuo Takeuchi, ``Manuscripting Editing on E-mail,'' 39th
;;	Programming Symposium, 1998, January, pp.61--68
;;
;;	The original paper is written in Japanese,
;;	�����ͺ, ``�Żҥ᡼��Ǹ��Ƥ���������ˡ --- Manuscript
;;     Editing (Manued, ���ƻ)���ܻؤ��� ---'', �� 39 ��ץ���ߥ�
;;	������ݥ�����, 1998, 1��, pp.61--68

;;; Code:

;;------------------------------------------------------------
;; debug �Ѥ� message ����
;;------------------------------------------------------------
;; delete at release
;;(setq debug-on-error t)
;;(defun dbg (mes) (print mes (get-buffer "manued-debug")))

;;------------------------------------------------------------
;; constant values
;;------------------------------------------------------------
(defconst manued-version-num   "0.9.5-current"
  "The version of manued.el.
���ƻ�ΥС������")

(defconst manued-build-day "2002-8-12"
  "The day of last change of manued.el.
���ƻ�κǽ�������")

(defconst manued-formatted-buffer-name "*manued*"
  "Buffer name of formatted manued text.
���ƻ�������ѤߥХåե�̾")

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
  "pstr ���饳�ޥ�ɤν��� point ���֤�"
  `(car ,pstr))

(defmacro manued-get-end-point (pstr)
  "pstr ���饳�ޥ�ɤν����� point ���֤�"
  `(car (cdr ,pstr)))

(defmacro manued-get-command-str (pstr)
  "pstr ���饳�ޥ��ʸ������֤�"
  `(car (cdr (cdr ,pstr))))

(defmacro manued-command-eq (pstr command-chars)
  "pstr ��Υ��ޥ��ʸ���󤬥��ޥ��ʸ����(command-chars)�Ȱ��פ����
��� t ���֤�"
  `(string-equal
    (manued-get-command-str ,pstr) ,command-chars))

;;;------------------------------------------------------------
;;; manued version
;;;------------------------------------------------------------
(defun manued-show-version ()
  "Print manued version.
manued �ΥС��������Τ餻��."
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
���ƻ�Υ��ޥ�ɤΤϤ��ޤ�򼨤�ʸ����")
(make-variable-buffer-local 'manued-l-parenthesis-str)

(defvar manued-r-parenthesis-str "]"
  "* End string of manued command. : default is `]'
���ƻ�Υ��ޥ�ɤν�λ�򼨤�ʸ����")
(make-variable-buffer-local 'manued-r-parenthesis-str)

(defvar manued-swap-str "|"
  "* String of manued swap-command. : default is '|'
	'A|B|C' means to swap A with C, then A|B|C will be C|B|A.
	Especially, 'A||C' means to swap A and C, then A||C will be C||A.
�򴹥��ޥ��ʸ���� : �ǥե���Ȥ� '|':
	A|B|C �ʤ�� A �� C �����촹���롥�������ä� A|B|C �� C|B|A �Ȥʤ롥
	�ä� 'A||C' �� A �� C �����촹�����̣���롥�������äơ�
	A||C �� C||A �Ȥʤ롥")
(make-variable-buffer-local 'manued-swap-str)

(defvar manued-delete-str "/"
  "* String of manued delete-command . : default is '/'
	'A/B' means to substitute A by B, then A/B will be B.
	Especially, '/B' means to insert B and 'A/' means to delete A.
�õ�ޥ��ʸ���� �ǥե���Ȥ� '/':
	A/B �ʤ�� A �� B ���֤������롥
	�ä� '/B' �� B ���������̣����'A/' �� A �κ�����̣����.")
(make-variable-buffer-local 'manued-delete-str)

(defvar manued-comment-str ";"
  "* String of maenud comment command. : default is `;'
comment out until manued-r-parenthesis-str.
������ʸ���� �ǥե���Ȥ� ';':
	���ƻ���ޥ�ɤν���ޤǤ򥳥��ȤȤߤʤ���")
(make-variable-buffer-local 'manued-comment-str)

(defvar manued-escape-str "~"
  "* Escape string. : default is `~'
This string can escape a next adjacent manued command.
����������ʸ�����ǥե���Ȥ� '~':
	���ο��ƻ���ޥ��ʸ���򥨥������פ��롥")
(make-variable-buffer-local 'manued-escape-str)

(defvar manued-pretty-print-format-delete-list
  '("\\textnormal{%s}" "\\textbf{%s}" "\\textit{%s}")
  "* manued pretty print format strings list for delete command.
'(delete-part-format replaced-part-format comment-part-format)
as the default, [A/B;C] will be print out:
  \\textnormal{A}\\textbf{B}\\textit{C}
�õ�ޥ���Ѥ� pretty print �κݤ����Ѥ���� format �Υꥹ��
�ǥե���ȤǤϡ�[A/B;C] �ϼ��Τ褦�˽��Ϥ����:
  \\textnormal{A}\\textbf{B}\\textit{C}")
(make-variable-buffer-local 'manued-pretty-print-format-delete-list)

(defvar manued-pretty-print-format-swap-list
  '("\\textbf{%s}---" "\\textbf{%s}" "---\\textbf{%s}" "(\\textit{%s})")
  "* manued pretty print format strings list for swap command.
'(alpha-part-format beta-part-format gamma-part-format comment-part-format)
as the default, [A|B|C;D] will be print out:
 \\textbf{%s}---\\textbf{%s}---\\textbf{%s}(\\textit{%s})
�򴹥��ޥ���Ѥ� pretty print �κݤ����Ѥ���� format �Υꥹ��
�ǥե���ȤǤϡ�[A|B|C;D] �ϼ��Τ褦�˽��Ϥ����:
 \\textbf{%s}---\\textbf{%s}---\\textbf{%s}(\\textit{%s})
")
(make-variable-buffer-local 'manued-pretty-print-format-swap-list)

(defvar manued-pretty-print-on-p nil
  "* manued pretty print on.
If this is t, you will get revised/original document with pretty
print style. The style will be changed by variables
manued-pretty-print-format-swap-list and
manued-pretty-print-format-delete-list.
pretty print �� off �ˤ��롥
�⤷�����ͤ� t �ξ��ˤϡ�ʸ��������������� pretty print style ��
���Ϥ���ޤ������Υ���������ѿ� manued-pretty-print-format-swap-list ��
manued-pretty-print-format-delete-list �����椵��ޤ���")
(make-variable-buffer-local 'manued-pretty-print-on-p)

(defvar manued-pretty-print-null-comment-out-p nil
  "* When t and there is no comment part, comment is considered as
\"\" and output comment part in pretty print mode. When nil and there
is no comment part, no output for comment part. Notice. This is not
buffer local variable.
�����ͤ� t �ξ��Ǥ��ĥ����Ȥ�̵����硤���Υ����Ȥ�����ȹͤ���
format �ΰ����� \"\" ���Ϥ��졤���Ϥ���ޤ����⤷�����ѿ��� nil �ξ���
��������ʬ��¸�ߤ��ʤ����ˤϡ���������ʬ�Ͻ��Ϥ���ޤ���
�����ѿ��� buffer local �ǤϤ���ޤ���")

(defconst manued-defversion-str manued-version-num
  "* String of manued version number. : default is same as version
number of this code.
�С�������ֹ�򼨤�ʸ�� : �ǥե���ȤϤ��Υ����ɤΥС�������ֹ�")

;;------------------------------
;; related `Find and set def* pattern'.
;;------------------------------
(defvar manued-doc-begin-pat "-*-*- BEGINMANUED -*-*-"
  "* This pattern indicates the beginning of a manued document.
Default is `-*-*- BEGINMANUED -*-*-'. There is no such pattern in
the document, start point of the manued document is set to `point-min'.
When this variable is nil, beginning point is always `point-min'.

���ƻ��ʸ��κǽ�򼨤�ʸ���󡥤���ʸ����ʸ�����¸�ߤ��ʤ����ˤ�
`point-min' ����Ƭ�Ȥ����Ѥ����롥�ޤ������Υ���ܥ뤬 nil �ξ���
�Ͼ�� `point-min' �����ƻʸ��λϤޤ�Ȥߤʤ���롥")
(make-variable-buffer-local 'manued-doc-begin-pat)

(defvar manued-doc-end-pat "-*-*- ENDMANUED -*-*-"
  "* This pattern indicates end of a manued document.
default is `-*-*- ENDMANUED -*-*-'. There is no such pattern in
the document, enx d point of the manued document is set to `point-max'.
When this variable is nil, beginning point is always `point-max'.

���ƻ��ʸ��κǸ�򼨤�ʸ���󡥤���ʸ����ʸ�����¸�ߤ��ʤ����ˤ�
`point-max' ���Ǹ�Ȥ����Ѥ����롥�ޤ������Υ���ܥ뤬 nil �ξ���
�Ͼ�� `point-max' �����ƻʸ��λϤޤ�Ȥߤʤ���롥")
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
���ƻ�Υ��ޥ��������ʸ����Ȥ��Υ���ܥ�")

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

����ʸ����Υꥹ�Ȥˤϡ����ƻ�Υ��ޥ��������ʸ����������ղä�����
���̵�뤹��ʸ�����ޤ�롥���Ȥ��� TeX ��ʸ����ǿ��ƻ�����Ѥ����
�硤�ʲ��Τ褦�˿��ƻ������ޥ�ɤ� TeX �Υ��������˴ޤ��

	%%defparentheses [ ]
	%%defdelete	 /

��������ȡ�manued.el �Ϥ���� defcommand �Ȥ���ǧ����������� TeX ��
�Ϥ�����ʬ��̵�뤹��Τǡ�Ʃ��Ū�� manued �����Ѳ�ǽ�Ǥ��롥")
(make-variable-buffer-local 'manued-defcommand-head-str-list)

;;--------------------
;; hilit related defvar
;;--------------------
(defvar manued-use-color-hilit 'follow-font-lock-mode
  "t when using color hilit. However `window-system' is nil, this
value is set to nil. When this is 'follow-font-lock-mode, follow font
lock mode.

����Ȥäƥϥ��饤�Ȥ�����ˤ� t����������window-system �� nil �ξ�
��ˤ� nil �����åȤ���롥'follow-font-lock-mode �ξ��ˤ�
font-lock-mode�˽�����")
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

���ƻ command �����ǥ�����ʸ�����������뤫���ʤ��������椹�롥t ��
���ˤ� default �� manued-insert-delete-command �ϥ�����ʸ�����������롥��
������manued-insert-delete-command-toggle-comment ���ޥ�ɤϵդ�ư��򤹤롥
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

���ƻ command �����ǥ�����ʸ�����������뤫���ʤ��������椹�롥t ��
���ˤ� default �� manued-insert-swap-command �ϥ�����ʸ�����������롥��
������manued-insert-swap-command-toggle-comment ���ޥ�ɤϵդ�ư��򤹤롥
")
(make-variable-buffer-local 'manued-is-swap-command-with-comment-on)


;;============================================================
;; Find and set def* pattern.
;;============================================================
;;
;; def* �θ���³�������ʸ����ʸ�����򤽤� def �Υѥ�����Ȥ���
;; ���ߤϰʲ��Τ�Τ򥵥ݡ��Ȥ��롥���Τ�Τ� default ��
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
;; �ǽ�ϰ��֤Υ���å���Ϥ��ʤ����Ȥˤ���
;; �����Խ����줿���ɤ����򸫤�褦�ˤ���
;;
;(defvar manued-doc-begin-point nil
;  "The cache of the beginnig point of manued document.
;   ���ƻʸ��Υ������ȥݥ���ȤΥ���å���")
;(defvar manued-doc-end-point nil
;  "The cache of the end point of manued document.
;  ���ƻʸ��Υ���ɥݥ���ȤΥ���å���")

;;
;; ���ƻʸ��ΤϤ����õ��
;;
(defun manued-get-doc-begin-point ()
  "Find beggining point of the manued document.
Find beginning pattern of a manued document and return the point. If
begging pattern is not founded in the manued document, return the
`point-min'. The beginning pattern is `manued-doc-begin-pat'.

���ƻʸ��κǽ�ΰ��֤�õ�������Υݥ���Ȥ��֤����⤷���ƻʸ����˿�
�ƻʸ�񳫻ϥѥ����󤬤ߤĤ���ʤ����ˤ�ʸ��κǽ� `point-min' ����
�֡����ƻʸ�񳫻ϥѥ������ `manued-doc-begin-pat' ���ݻ����Ƥ��롥"
  (if (null manued-doc-begin-pat)
      (point-min)
    (save-excursion
      (goto-char (point-min))
      (if (search-forward manued-doc-begin-pat nil t)
	  (match-beginning 0)		; found
	(point-min)))))			; not found

;;
;; ���ƻʸ��ν�����õ��
;;
(defun manued-get-doc-end-point ()
  "Find end point of the manued document.
Find end pattern of a manued document and return the point. If
end pattern is not founded in the manued document, return the
`point-max'. The end pattern is `manued-doc-end-pat'.

���ƻʸ��ν����ΰ��֤�õ�������Υݥ���Ȥ��֤����⤷���ƻʸ�����
���ƻʸ�񳫻ϥѥ����󤬤ߤĤ���ʤ����ˤ�ʸ��κǽ� `point-min' ��
���֡����ƻʸ�񳫻ϥѥ������ `manued-doc-begin-pat' ���ݻ����Ƥ��롥
"
  (if (null manued-doc-end-pat)
      (point-max)
    (save-excursion
      (goto-char (point-max))
      (if (search-backward manued-doc-end-pat nil t)
	  (match-end 0)			; found
	(point-max)))))			; not found

;;;------------------------------
;;; defcommand ��õ���ƥ��åȤ���
;;;------------------------------
;; ������ΰ�Ĥ� defcommand ��õ���ƥ��åȤ���
(defun manued-search-set-def-one (decstr-str)
  "Find a manued command definition string `decstr-str' and set manued
command pattern.
See also the `manued-def-alist' which is a list of manued command
declarations and variables.

��Ĥο��ƻ���ޥ�����ʸ���� `decstr-str' ��õ���Ƥ���ʸ������б���
��ʸ����򥻥åȤ��롥
`manued-def-alist' �����ƻ���ޥ�����ʸ����Ȥ����ѿ����ݻ����Ƥ���
�Τǻ��ȤΤ��ȡ�"
  (let ((non-whitespace-pat "[ |\t]+\\([^ |\t|$\n]+\\)"))
    (if (re-search-forward
	 (concat "^" (car decstr-str) non-whitespace-pat) nil t)
	(progn
	  (let ((b (match-beginning 1))	(e (match-end 1)))
	    (if (< b e)
		(set (car (cdr decstr-str))
		     (buffer-substring-no-properties b e))))))))

;; ������ΰ�Ĥ� defcommand ��õ���ƥ��åȤ���
(defun manued-search-set-defparentheses-with-comment (comment-str)
  "Find defparentheses and set values. This method is for
defparentheses only.

defparentheses ��õ�����ͤ򥻥åȤ��롥comment-str ����Ƭ���ղä���ʸ
����"
  (if (re-search-forward
       (concat "^" comment-str "defparentheses[ |\t]+") nil t)
      ;; ����Ǥʤ�2�Ĥΰ�����õ��������regex��ʣ���ŤͤƤ����л���
      ;; �Ĥΰ����򰷤����ȤˤϤʤ�
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
;; ���Ƥ� defcommand �򥻥åȤ���
;;
(defvar manued-header-is-found nil)	; header �����ƻʸ����ˤ��뤫
(defun manued-search-set-defcommands ()
  "find all manued command declarations in a dcument.
���Ƥο��ƻ���ޥ�����ʸ�����ʸ���椫��õ���Ф������ƻ���ޥ�ɤ򥻥�
�Ȥ��롥
See also `manued-search-set-oneargdefs'."
  ;; header��Ƥ�õ��
  (setq manued-header-is-found nil)
  ;; defparentheses ��õ�����åȤ��� :
  (manued-search-set-defparentheses)
  ;; ������� def* ��õ�����åȤ���
  (manued-search-set-oneargdefs manued-def-alist))

;;
;; defparentheses ��õ�������ͤ򥻥åȤ��� :
;;  �������defcommand�����2�����ʤΤ��̤ˤ��롥¾��ʣ�������Τ�Τ�
;;  �ФƤ�������Ƥ�defcommand��ʣ�������Ȥ��ư��̲������н褹�٤�������
;;  ���Ϥ��줷���ʤ��Τ�¿��add-hoc�ǤϤ��뤬�����Τ褦���н褷����
;;
(defun manued-search-set-defparentheses ()
  (goto-char (manued-get-doc-begin-point)) ; goto begin
  (if (manued-search-set-defparentheses-with-comment "") ; serach and set one
      (setq manued-header-is-found t)       ; �Ǥ� defparentheses ��ȯ��
    ;; defparentheses ���Ǥ�¸�ߤ��ʤ���祳����ʸ����ä��Ƥߤ�
    (let ((comment-head-list manued-defcommand-head-str-list))
      (while comment-head-list
	(if (manued-search-set-defparentheses-with-comment
	     (car comment-head-list))
	    (progn		; ������ + ���ޥ�ɤ�¸�ߤ���
	      (setq comment-head-list nil)
	      (setq manued-header-is-found t))
	  (setq comment-head-list (cdr comment-head-list)))))))

;;
;; manued-doc-begin-pat ������� manued-def-alist ��Υѥ�����˹���
;; ����ʸ�����õ�����ΰ����򥻥åȤ��롥�������defcommand�Τߤ򰷤���
;;
(defun manued-search-set-oneargdefs (def-alist)
  "find one argument manued command declarations in a dcument.
������ο��ƻ���ޥ�����ʸ�����ʸ���椫��õ���Ф������ƻ���ޥ�ɤ�
���åȤ��롥
See also `manued-search-set-def-one'."
  (while def-alist
    (goto-char (manued-get-doc-begin-point)) ; goto begin
    (let ((defcom (car def-alist)))
      (if (manued-search-set-def-one defcom) ; serach and set one
	  (setq manued-header-is-found t)   ; �Ǥ� defcommand ��ȯ��
	;; defcommand ���Ǥ�¸�ߤ��ʤ���祳����ʸ����ä��Ƥߤ�
	(let ((comment-head-list manued-defcommand-head-str-list))
	  (while comment-head-list
	    (if (manued-search-set-def-one
		 (cons (concat (car comment-head-list) (car defcom))
		       (cdr defcom)))
		(progn		; ������ + ���ޥ�ɤ�¸�ߤ���
		  (setq comment-head-list nil)
		  (setq manued-header-is-found t))
	      (setq comment-head-list (cdr comment-head-list)))))
	;; else list �����Ǥ�������������֤�
	))
    (setq def-alist (cdr def-alist)))
  ;; �Ť��С������Τ�Τȸߴ���������뤿��κ�Ȥ�Ԥ�
  (manued-dispatch-for-old-version)
  ;; defcommand �ΰ�������ݤ���Ƥ��뤫
  (manued-check-defcommand-consistency)
  ;; ���� defcommand �򥻥åȤ����� order ����� (deforder ��ȿ�Ǥ�����)
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
;;; manued-order-str ���ͤˤ�ä� order �����
;;;------------------------------------------------------------
;; order indicating string
(defvar manued-order-str "older-first"
  "* delete order.
The form of the manued command is [first/last]. ``older''
indicates original document and ``newer'' indicates revised
document. This string sets the variable `manued-is-order-older-first'.

���ƻ�õ�ޥ�ɤ�Ŭ�ѽ硥�õ�ޥ�ɤ����Ƥ� [first/last]
�Ȥ��롥 `older' �ϸ�ʸ���`newer' ���ѹ����ʸ��򼨤�������ʸ����
�ˤ������ä� `manued-is-order-older-first' ���ͤ����åȤ���롥

-------------------------+-----------------+----------------------------
manued-order-str         | change from to  | manued-is-order-older-first
-------------------------+-----------------+----------------------------
 older-first, newer-last |  first -> last  |           t
 older-last,  newer-first|  last  -> first |          nil
-------------------------+-----------------+----------------------------")

(defvar manued-is-order-older-first t
  "Applying swap-command order.
When t, [first/last] will change first -> last.

�õ�ޥ�ɤ� [first/last] �Τɤ��餬�����褫�򼨤���
[������/������]�ξ��� t�����ε� ([������/������]) �λ��� nil��")

;;
;; set delete command order according to order string
;;	order ʸ����˽��ä� delete command ���������ꤹ��
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

�Хåե��� defcommand �����������������

`is-auto-insert' �� t �ξ�硤�⤷���ߤΥХåե���defcommand��̵������
��manued.el��defcommand�򸽺ߤΥХåե����������ޤ���nil�ξ��ˤϲ��⤷
�ޤ���

2���ܤ�����`is-query-when-insert'��t�ξ�硤manued.el�ϥ桼����
defcommand�����������ɤ����Ҥͤ�褦�ˤʤ�ޤ���nil�ξ��ˤϿҤͤޤ���
����ϡ�`is-auto-insert'��t�ξ���ͭ���Ǥ���

3���ܤ����ǤǤ���`insert-point'��defcommand���������֤���ꤹ���Τǡ�
���Τ褦�ʰ�̣������ޤ���

    t         ���ߤΥݥ����
    nil       (point-min)
    number    �����Ǽ�����point����
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
	   ;; �� eval ��ȤäƤ�������symbol-value ��Ȥ�
	   (format "%s\t%s\n" (car item) (symbol-value (car (cdr item))))))
      (setq defalist (cdr defalist)))))
;;
;; when non exist header,  insert manued header with quary
;;
(defun manued-search-and-insert-header ()
  "���ƻ def ���ޥ�ɤ򥵡�������¸�ߤ��ʤ����ˤ��������뤫�Ҥͤ롥

see variable : manued-is-auto-insert-header"
  (save-excursion
    (if (and (car manued-is-auto-insert-header)
	     (not manued-header-is-found)) ; mode ������ݤ�ɬ���ƤФ�Ƥ���
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

recenter ������˿��ƻ���ޥ�ɤ� hilit ���롥��������hilit ��Ԥ��Τ�
color mode �� off �λ��Τߡ�"
  (interactive)
  (manued-hilit)
  (recenter))

;;------------------------------
;; ���� hilit ���٤���Τ򼨤�.
;; manued-hilit ���ƤФ줿���ˤϤ����ѿ��򸫤� hilit-older ��
;; hilit-newer ����Ƚ�ꤹ�롥t �ΤȤ��ˤ� newer �� hilit ���롥
;;------------------------------
(defvar manued-is-now-hilit-newer t)

;;------------------------------
;; hilit
;;------------------------------
(defun manued-hilit ()
  "hilit manued command.
When `manued-use-color-hilit' is t, hilit manued command according to
the value of `manued-is-now-hilit-newer'.

���ƻ���ޥ�ɤ� hilit ���롥
�⤷ `manued-use-color-hilit' �� t �ʤ�� manued command �� hilit ���롥
���λ���`manued-is-now-hilit-newer' �� t �ʤ�� newer �� hilit ����nil
�ʤ�� older �� hilit ���롥"
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
ʸ����ο��ƻ���ޥ�������������ʬ��ϥ��饤�Ȥ��롥"
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
ʸ����ο��ƻ���ޥ�������������ʬ��ϥ��饤�Ȥ��롥"
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
���ƻ��ʸ����Υ��ޥ�ɤ����ƥϥ��饤�Ȥ��롥"
  (let ((cont t))
    (while cont
      (let ((lap (manued-search-nonescaped-command-in-hirabun ; [ ��õ��
		  (manued-get-doc-end-point))))
	(if lap				; found [. ���� lap �� [ �Ǥ���
	    (progn
	      (manued-hilit-one-command lap)
	      ;; colored-pos-pstr �Ϥ���ޤǿ����ɤä����򼨤����Ū
	      ;; �ݥ��󥿡��ǽ�� region �� delete-first �Ȳ��ꤹ��
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
	  (manued-hilit-one-command lap) ; ���ޥ�ɽ���
	  ;; ����ޤǤ��ϰϤ����
	  (cond
	   ;; ; comment in and exit this level
	   ((manued-command-eq lap manued-comment-str)
	    (if (or (eq cur-command 'manued-com-delete-first)
		    (eq cur-command 'manued-com-delete-last)
		    (eq cur-command 'manued-com-swap-gamma))
		(progn (manued-hilit-one-region
			colored-pos-pstr lap cur-command)
		       ;; ���� cur-command �� hilit-commet ��������
		       ;; �Ȥ������Ȥ��ΤäƤ���ΤǾ�Ĺ�������ץ���
		       ;; ��Ȥ��Ƥΰ�������뤿��ˤ����� setq ����
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
	      (setq cur-command 'manued-com-swap-alpha) ; ������swap�Ȥ狼��
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
;; ��λ�γ�̤��ߤĤ���ʤ����Υ��顼����
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
;; ��Ĥ� manued ���ޥ�� (ex. [, ], /, |, ;) �� hilit
;;
(defun manued-hilit-one-command (pstr)
  "��Ĥο��ƻ���ޥ�ɤ� hilit ���롥"
  (put-text-property (manued-get-first-point pstr)
		     (manued-get-end-point   pstr)
		     'face
		     'manued-command-face))

;;
;; ���ꤷ�����ǻ����ϰϤ� hilit
;;
(defun manued-hilit-one-color (begin-pstr end-pstr color)
  "���ƻ���ޥ�����Ϣ³������ʬ����ꤷ������ hilit ���롥

hilit a manued region with indicated color-face."
  (put-text-property  (manued-get-end-point   begin-pstr)
		      (manued-get-first-point end-pstr)
                      'face
		      color))

;;
;; �����ϰϤ򿧤����򤷤ƥϥ��饤�Ȥ���
;; �ɤ��ޤǿ����ɤä����� colored-pos-pstr �˵�Ͽ����
;;
(defun manued-hilit-one-region (beg-pstr end-pstr cur-command)
  "hilit a manued command region.
��Ĥο��ƻ���ޥ�ɤ��ϰϤ���ꤹ��Ȥ����ϰϤ�ϥ��饤�Ȥ��롥"
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
  "hilit ��������"
  (let ((color-sym '(manued-delete-first-face
		     manued-delete-last-face
		     manued-swap-alpha-face
		     manued-swap-beta-face
		     manued-swap-gamma-face
		     manued-comment-face
		     manued-command-face))
	(color-val color-val-list))
    ;; (mapcar 'set color-sym color-val) �� elisp �ǤϤǤ��ʤ��������ϰ��
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
;; ���������פ�ͤ��ƥ��ޥ�ɤ򥵡�������
;;
;; ���������פΰ�̣�ϡ��֥���������ʸ���μ���ʸ�������Ф��פȤ�������
;; ���������
;;
(defun manued-search-nonescaped-command (coms-regpat end-point)
  "���������פ��θ���ƥ��ޥ�ɤ򥵡������롥
search-coms-regpat : ���������� command ʸ���� regex �ѥ�����
end-point          : �ɤ��ޤ�õ����(point)

escape ����Ƥ��ʤ����ޥ�ɤ�õ�����ߤĤ��ä��餽�Υ��ޥ�ɤ�
``begin-point end-point ���ޥ��ʸ����'' �Υꥹ�Ȥ��֤����ߤĤ����
���ä��� nil���֤�"
  (catch 'tag
    (while t
      (let ((find-com (manued-search-command coms-regpat end-point)))
	(if (not find-com)
	    (throw 'tag nil)		; ���ޥ�ɤϤʤ�
	  ;; escape ʸ���ξ��ˤϥ��������� escape �� L-parenthesis
	  ;; �Ȥ��Ȥ�Ϳ�����Ƥ��롥ex. ~[
	  (let (; (fpos (manued-get-first-point find-com))  ; ���ޥ�ɷ��κǽ�
		(epos (manued-get-end-point   find-com))) ; �����
	    (goto-char (manued-get-first-point find-com)) ; ���ޥ�ɰ��֤ذ�ư
	    (if (looking-at (regexp-quote manued-escape-str)) ; escape ʸ����?
		(progn			; escape str ���ä�
		  (goto-char epos)	; esc�θ�ذ�ư ESCPAT^COMPAT
		  (forward-char 1))	; 1ʸ�����Ф�
	      (progn			; escape ʸ���Ǥʤ��ä�
		(goto-char epos)	; 'COMPAT^'
		(throw 'tag find-com)))))))))

;;
;; serach-command (search-coms-regpat end-point)
;; ex.	(manued-search-command "��\\|��\\|/\\|;\\|~"
;;	  (manued-get-doc-end-point))
;;	���ޥ�ɤΤߤ򥵡�������
;;
(defun manued-search-command (search-coms-regpat end-point)
  "manued ���ޥ�ɤ�õ��. ���������פϹ�θ���ʤ���
search-coms-regpat : ���������� command ʸ���� regex �ѥ�����
end-point          : �ɤ��ޤ�õ����(point)

�ޥå��������ޥ�ɤ� (begin-point end-point ``���ޥ��ʸ����'') ��
�ꥹ�Ȥ��֤����ߤĤ���ʤ��ä��� nil ���֤����ϰϤγ�����õ���Ϥ���
��ˤ� re-search-forward �� NOERRROR �ϸ����ʤ��餷���Τ��к���֤���
������"
  (if (<= end-point (point))
      nil
    (if (re-search-forward search-coms-regpat end-point t)
	(list (match-beginning 0)
	      (match-end 0)
	      (buffer-substring (match-beginning 0) (match-end 0)))
      nil)))

;;
;; search-command-in-hirabun
;;  ʿʸ��ǿ��ƻ���ޥ�ɤ�õ��
;;
;;  ʿʸ��� `~' �����ޥ�ɤǤʤ��ˤ⤫����餺��`~[' �ϥ��������פ���
;;  �ʤ��ƤϤʤ�ʤ��Ȥ����ü�������ˤ���������ϻȤ��פ��Τ���Ǥ��롥
;;  ʿʸ��ǹ�θ���ʤ��ƤϤʤ�ʤ�ʸ���� `~' �� `[' �ˤ���ΤǤϤʤ���
;;  `[' �����ˤ������ȹͤ�����
;;
(defun manued-search-nonescaped-command-in-hirabun (end-point)
  "search manued command in normal text region

end-point : where to search.

���������פ���Ƥ��ʤ�ʿʸ��ο��ƻ���ޥ�ɤλϤޤ��õ��"
  (catch 'tag
    (while t
      (let ((find-com (manued-search-command
		       (manued-hirabun-command-pat) end-point)))
	(if (not find-com)
	    (throw 'tag nil)		; ���ޥ�ɤϤʤ�
	  (if (not (manued-command-eq find-com (manued-escaped-l-paren-pat)))
	      (throw 'tag find-com)))))))

;;------------------------------------------------------------
;; ���ޥ��ʸ������
;;------------------------------------------------------------
;; ʿʸ�Ǥ� [ �� ~[ ���������
;;
(defun manued-hirabun-command-pat ()
  "ʿʸ���鿿�ƻ��������Υ��ޥ��ʸ�����������"
  (concat
   (regexp-quote manued-l-parenthesis-str) "\\|"
   (manued-escaped-l-paren-pat)))

;; ]
(defun manued-outof-command-pat ()
  "���ƻ���ޥ�ɤ���Ф���Υ��ޥ��ʸ�����������"
  (concat
   (regexp-quote manued-r-parenthesis-str) 	"\\|"
   (regexp-quote manued-escape-str)))


;; �����ޥ��ʸ��
(defun manued-all-command-pat ()
  "���ƻ�����ޥ��ʸ�����������"
  (concat
   (regexp-quote manued-l-parenthesis-str) 	"\\|"
   (regexp-quote manued-r-parenthesis-str) 	"\\|"
   (regexp-quote manued-delete-str)		"\\|"
   (regexp-quote manued-swap-str)		"\\|"
   (regexp-quote manued-comment-str)		"\\|"
   (regexp-quote manued-escape-str)))

;; ~[ ʸ��
(defun manued-escaped-l-paren-pat ()
  (concat (regexp-quote manued-escape-str)
	  (regexp-quote manued-l-parenthesis-str)))

;; regrex �˻Ȥ��ʤ���ȯ������ʸ���Υޥå��˻Ȥ� ~[ ʸ��
(defun manued-escaped-l-paren-str ()
  (concat manued-escape-str manued-l-parenthesis-str))

(defvar manued-ask-if-formatted-buffer-is t
  "* ���������Ѥߤ� buffer ��¸�ߤ������˿Ҥͤ뤫�ɤ�����t �ǿҤͤƤ���")

;; 1998ǯ6��27��(��)
;; �������οͤ������������򼰤˽Ф�����꤭��̡��ޤä�������꤭���

;;;============================================================
;;; ������ manued �����ѥХåե��κ���
;;;============================================================
;; �����ʥХåե��κ���
(defun manued-get-format-buffer ()
  "get a formatting buffer for manued.

If no manued buffer, create and return it. Otherwise, ask to the user
overwrite or not. However, if manued-ask-if-formatted-buffer-is is
nil, never ask and override the buffer.

���ƻ�������ѤΥХåե���������롥̵�����ˤϺ�ä��֤���ͭ�����
�Ͼä����ɤ����Ҥͤ롥��������manued-ask-if-formatted-buffer-is �� nil
�λ��ˤϿҤͤ��˺������롥"
  (if (null (get-buffer manued-formatted-buffer-name))
      (get-buffer-create manued-formatted-buffer-name)
	;; ����¸�ߤ���
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
;; show : �������ޥ��
;;============================================================
;;
;; show newer
;;
(defvar manued-show-newer-p nil)
(defun manued-show-newer-in-manued-buffer ()
  "Show revised document from current manued document to another buffer.
���ߤΥХåե��ο��ƻʸ����ѹ����ʸ���¾�ΥХåե���ɽ�����롥"
  (interactive)
  (manued-show-in-manued-buffer t manued-pretty-print-on-p))

;;
;; show newer document with region
;;
(defun manued-show-newer-region (b e)
  "Show newer version with region.
�꡼�������ϰϤ��������ƿ�����ʸ�����Ф�"
  (interactive "r")
  (setq manued-show-newer-p t)
  ;; (dbg (format "b = %d, e = %d" b e))
  (manued-show-region b e))

;;
;; show older
;;
(defun manued-show-older-in-manued-buffer ()
  "Show original document from current manued document to another buffer.
ʸ����ο��ƻ���ޥ�ɤ��ѹ�����ʸ���¾�ΥХåե���ɽ�����롥"
  (interactive)
  (manued-show-in-manued-buffer nil manued-pretty-print-on-p))

;;
;; show older document with region
;;
(defun manued-show-older-region (b e)
  "Show older version with region.
�꡼�������ϰϤ��������ƸŤ�ʸ�����Ф�"
  (interactive "r")
  (setq manued-show-newer-p nil)
  (manued-show-region b e))

;;
;; show revised document at another buffer
;;	¾�ΥХåե����ꡤ���������Ƥ򥳥ԡ�������������
;;
(defun manued-show-in-manued-buffer (show-newer-p pretty-print-p)
  "Show processed manued document to another buffer.

When show-newer-p is t, newer document is shown. Otherwise, older
document is shown.

ʸ����ο��ƻ���ޥ����θ�ʸ���¾�ΥХåե���ɽ�����롥
show-newer-p �� t �ʤ鿷��������ɽ������nil �ʤ�Ť�����ɽ�����롥"
  (let ((formatbuf (manued-get-format-buffer)))
    (if formatbuf
	(let ((orgbuf (current-buffer)))	; ���ߤ� buffer
	  (pop-to-buffer formatbuf)
	  (insert-buffer orgbuf)
	  (setq manued-show-newer-p      show-newer-p)
	  (setq manued-pretty-print-on-p pretty-print-p)
	  (manued-show-buffer)))))

;;
;; ���ߤΥХåե��ο��ƻ���ޥ�ɤ�������Ԥ�
;;
(defun manued-show-buffer ()
  "���ߤΥХåե��ο��ƻ���ޥ�ɤ��������롥
���ߤ� manued-show-newer-p ��������ʬ����Ф���"
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
;; ���ߤΥХåե��� region �ǻ��ꤵ�줿�ϰϤο��ƻ���ޥ�ɤ�������Ԥ�
;;
(defun manued-show-region (b e)
  "���ߤΥХåե��ο��ƻ���ޥ�ɤ��������롥
���ߤ� manued-show-newer-p ��������ʬ����Ф���"
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
  "���ƻʸ���ʿʸ��Υ��ޥ�ɤ�������롥"
  (let ((cont t))
    (while cont
      (let ((lap
	     (manued-search-command (manued-hirabun-command-pat)
				    (marker-position region-end-marker))))
	(cond
	 ((eq lap nil)			; lap is nil ... command is not found.
	  (setq cont nil))		; ���ƽ�������: exit loop

	 ;; ~[ ʿʸ��Υ��������׳�̤ν���
	 ((string-equal (manued-escaped-l-paren-str)
			(manued-get-command-str lap))
	  (let ((m (make-marker)))
	    (set-marker m (manued-get-end-point lap)) ; ~[^ �ν����˥ޡ���
	    (manued-proc-escape (manued-get-first-point lap)
				(manued-get-end-point   lap))
	    (goto-char (marker-position m))
	    (set-marker m nil)))

	 ;; [ ���ƻ���ޥ�ɤν���
	 (t
	  (manued-replace-manued-term lap region-end-marker)))))))

;;
;; �ޤ������ [] ��ߤĤ��뤽���Ƥ��κ��⿿�ƻ���ޥ�ɤ���Ƶ�Ū�˽���
;; �Ƶ�Ū�˽����򤷤Ƥ�ʸ����������Ǹ��Ф��� point ���Ѳ����ʤ�
;;
;; lap = LookAhead-Pstr
;;
(defun manued-replace-manued-term (beg-lap region-end-marker)
  (let ((cont t)
	(lap nil)			; lookahead-pstr
	(swap-pstr-list   '())		; swap   ����Υꥹ��
	(delete-pstr-list '())		; delete ����Υꥹ��
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
;; ���ޥ�ɤ��������Υ����å�
;;   beg-lap �ϥ��顼��ȯ�����򼨤�����
;;
(defun manued-check-command (swap-symcount delete-symcount beg-lap)
  (catch 'tag
    (let ((permitted-occur-num-list	; ��������ȹ礻
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
;; ���ޥ�ɤˤ�ä��������ޥ�ɤ�ƤӽФ�
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
;; swap ���ޥ�ɤ��������
;; 	[alpha|beta|gamma;comment]
;; ���르�ꥺ��γ���
;; �ä��� insert ���뤳�Ȥ����촹����Ԥ���insert �θ�˥ݥ���Ȥ����
;; �ΤǤ��ξ�ǥޡ���������ϰϤκǸ夬�狼�롥������ escape ���������
;; �Ǹ�˰�ư���롥
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
;; delete ���ޥ�ɤ��������
;;   Escape �����Υ��르�ꥺ��� swap ��Ʊ��
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
;; null ���ޥ�ɤ��������
;;	null ���ޥ�ɤϾõ�Ƥ��ޤä��ɤ�����
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
;; 	begin-point ���� end-point �ޤǤδ֤� escape ���������
;;
(defun manued-proc-escape (begin-point end-point)
  "process escape
  begin-point end-point �ޤǤ�¸�ߤ��륨�������פν���"
  (goto-char end-point)
  (let ((m-end (point-marker))		; �Խ�����Ѳ�����ΤǺǸ�˰�
	(m-cont nil))
    (goto-char begin-point)
    (let ((esc-pstr t))
      (while esc-pstr			; �ϰ���� escape ʸ��������¤�
	(setq esc-pstr (manued-search-command
			(regexp-quote manued-escape-str)
			(marker-position m-end)))
	(if (not (null esc-pstr))
	    (progn
	      (goto-char (manued-get-end-point esc-pstr))
	      (setq m-cont (point-marker)) ; esc �κǸ�� mark
	      (delete-region (manued-get-first-point esc-pstr) ; del esc str
			     (manued-get-end-point   esc-pstr))
	      (goto-char (marker-position m-cont)) ; esc ��ľ��˰�ư
	      (set-marker m-cont nil)
	      (forward-char 1))		; esc �μ���ʸ�������Ф�
	  ;; else (null esc-pstr) �ʤ齪λ
	  )))
    (set-marker m-end nil)))


;;
;; ��λ�γ�̤��ߤĤ���ʤ����Υ��顼����
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
  "delete command ���������˥�����������ǥե���Ȥȵդˤ���
manued-is-delete-command-with-comment-on ��դξ��֤ˤ���
manued-insert-delete-command ��Ƥ֡�"
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
    (goto-char e)			; ������������
    (if manued-is-order-older-first	; [region/]
	(progn
	  (insert manued-delete-str)	; /
	  (setq imark (point-marker))	; /^
	  (if manued-is-delete-command-with-comment-on
	      (insert manued-comment-str)))) ; /^;
    (insert manued-r-parenthesis-str)	; /^;] or /^]
    (goto-char b)			; ������
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
  "swap command ���������˥�����������ǥե���Ȥȵդˤ���
manued-is-swap-command-with-comment-on ��դξ��֤ˤ���
manued-insert-swap-command ��Ƥ֡�"
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
    (goto-char e)			; ������������ [region||]
    (insert manued-swap-str)		; |
    (setq imark (point-marker))		; |^|
    (insert manued-swap-str)		; |^|
    (if manued-is-swap-command-with-comment-on
	(insert manued-comment-str))	; ||^;
    (insert manued-r-parenthesis-str)	; ||^;] or ||^]
    (goto-char b)			; ������
    (insert manued-l-parenthesis-str)	; [
    (goto-char (marker-position imark))
    (set-marker imark nil)))		; for GC

;;------------------------------
;; insert manued comment
;;    �����ѿ��ˤ�äư����ΰ㤦�ؿ���Ƥ֤ΤϤɤ�����Τ�
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
;; insert manued comment with region 1998ǯ8��11��(��)
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
    ;; mark �������������������ˤ� [; ��ʬ��ư���Ƥ������ϤǤ���褦�ˤ���
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

ľ���ΰ�Ĥο��ƻ���ޥ�ɤ�ɾ����Ԥ���eval-last-sexp ��Ʊ�͡�������
Ϳ����ȸ��ߤ� newer �ʤ�� older �򡤤Ȥ����褦�˵դ�ư��򤹤롥����
������������ǽ�˥ޥå����� manued-l-parenthesis-str ��õ���Τǡ�����
��������˿��ƻ���ޥ�ɤ�������ˤ���������������ʤ����⤷��ʤ���
���Ȥ��о����Τ褦�ʾ�礬���롥"
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
;; escape ����Ƥ��ʤ���̤�õ��
;;
(defun manued-lastexp-detect-pat ()
  (concat
   (regexp-quote manued-l-parenthesis-str) 				"\\|"
   (regexp-quote manued-r-parenthesis-str)))

;;
;; escape ����Ƥ����Τ�õ���ʤ�
;;
(defun manued-lastexp-non-detect-pat ()
  (concat
   (regexp-quote (concat manued-escape-str manued-l-parenthesis-str))	"\\|"
   (regexp-quote (concat manued-escape-str manued-r-parenthesis-str))))

;;
;; �������������� def[LR]parenthesis �Τߤ�õ������
;;
;; backword �� regex �������񤤤Ƥ��Ĺ���פǤʤ��褦�Ǥ��롥�ޥ˥�
;; ����ˤ��ȡ�re-search-backword �� re-search-forward �δ����ʥߥ顼
;; �ǤϤʤ��Ȥ������Ȥ��������ࡥ
;;
(defun manued-search-last-command-backword-pstr ()
  (let ((ret-pstr nil) (cont t) (found nil))
    (while cont
      (if (null (re-search-backward (manued-lastexp-detect-pat)
				    (manued-get-doc-begin-point) t))
	  (setq cont nil)		; re-search-backward �˼���
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
		      ;; ��Ω��̤��ߤĤ��ä��ʤ���äƤ���
		      (goto-char (+ (point) (length manued-escape-str))))
		  ;; ���ιԤǤ� ~]�� ~[ �ʤΤ�̵�뤷�Ƽ��� while loop ����
		  ))
	    (progn
	      (setq found t)
	      (setq cont nil))))))	; ����ʾ����ˤϤ����ʤ��Τ�ȯ��
    (if found
	ret-pstr			;ȯ�����Ƥ�����
      nil)))

;;============================================================
;; initialize manued
;;	initialize variables and get defcommands.
;;============================================================
(defun manued-init-vars ()
  "Initialize variables.
	search and get document begin point and end point.
	���ƻʸ���椫��ɬ�פʾ������Ф�����������롥"
  (save-excursion
    ;;(setq manued-doc-begin-point nil)
    ;;(setq manued-doc-end-point   nil)
    (manued-get-doc-begin-point)
    (manued-get-doc-end-point)
    ;; defcommand��õ�����ͤ򥻥åȤ���
    (manued-search-set-defcommands)
    ;; color mode ���Ȥ��ʤ��褦�ʤ� off �ˤ���
    (if (not window-system)
	;; not window-system
	(progn
	  (if manued-use-color-hilit	; ���λ���hilit�϶���Ū��off
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
		;; mule, emacs20 �Ǥ�font-lock-mode�ȶ�¸�Ǥ��Ƥ��ʤ���
		t)))
	(t manued-use-color-hilit)))	; follow �Ǥʤ���Ф����ͤ��֤�

;;============================================================
;; manued-minor-mode
;;	Manued has the minor-mode only.
;;============================================================
;; menu-bar
;;	���ƻ��˥塼
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
;; ���ƻ�� minor mode keymap
;;------------------------------
(defvar manued-minor-mode-map nil
  "* keymap of manued. minor mode.
   ���ƻ�Υ����ޥå�:
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
���ƻ�⡼�ɤ� syntax table : default �ͤ� `text-mode-syntax-table'")

(defvar manued-mode-abbrev-table text-mode-abbrev-table
  "* abbrev table of manued mode : default is `text-mode-abbrev-table'
���ƻ�⡼�ɤ� abbrev table : default �ͤ� `text-mode-abbrev-table'")

;;------------------------------------------------------------
;; ���ΥС������Ȥκ�ʬ��ۼ�����
;;	�����������Ǥļ꤬�ʤ���
;;	�إå����ʤ��Τ��С�����󤬸Ť��Τ��Ϥɤ����褦��ʤ���������
;;------------------------------------------------------------
(defun manued-dispatch-for-old-version ()
  (progn
    ;; swap-str �� delete-str �ȴְ㤨�Ƥ����С��������
    ;; ������ string= �Ǥʤ� match �ʤΤ���ʬŪ��Ʊ���������꤬ȯ��
    ;; ���뤫�ȹͤ������� ex. defparentheses ( ), defswap )| �ξ��
    ;; (a/b)�μ��� | ��ʿʸ��˽Ф����˺��롥�Ȼפ�����Ƥߤ褦
    (if (string-match manued-swap-str manued-delete-str)
    ;; (if (string-equal manued-swap-str manued-delete-str)
	(if (y-or-n-p
	     "Buffer is edited by old manued.el. Change swap-str defs?")
	    (progn
	      (setq manued-swap-str "|")
	      (setq manued-delete-str "/"))))
    ;; defLparenthesis, defRparenthesis ��¸�ߤ�����˷ٹ𤹤�
    (goto-char (manued-get-doc-begin-point))
    (if (re-search-forward "def[LR]parenthesis" nil t)
	(progn
	  (ding)
	  (message
	   "def[LR]parenthesis is supported but obsolete, use defparentheses")
	  (sit-for 1)))))
;; version ��� (string< "1.0.0" "1.0.10") �ξ��ˤϼ��Ԥ��롥����

;;============================================================
;; ���ƻ minor �⡼�ɤ����롥
;;============================================================
(defvar manued-minor-mode nil)		; ���ƻ minor mode �ˤ��뤫�ɤ���
(defvar manued-pushd-menubar nil)	; ���� Menubar ����¸����
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
�ޥ��ʡ��⡼��

��������ʸ��Υϥ��饤��		\\[manued-hilit-older]
�������ʸ��Υϥ��饤��		\\[manued-hilit-newer]
�ƥϥ��饤��			\\[manued-hilit]
��������ʸ����̤ΥХåե���ɽ��	\\[manued-show-older-in-manued-buffer]
�������ʸ����̤ΥХåե���ɽ��	\\[manued-show-newer-in-manued-buffer]
��������ʸ���pretty print���������ɽ��	\\[manued-set-pretty-print-on]
��������ʸ����̾�Υ��������ɽ��	\\[manued-set-pretty-print-off]

���ƻ delete ���ޥ�ɤ�����		\\[manued-insert-delete-command]
���ƻ swap ���ޥ�ɤ�����		\\[manued-insert-swap-command]
���ƻ comment ������			\\[manued-insert-comment]
ľ���ο��ƻ���ޥ�ɤ�ɾ��	       	\\[manued-eval-last-manuexp]

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
;; �ɤ���顤xemacs�Ǥʤ�Emacs�Ǥ�easymenu��add, delete�ޤǤߤƤ����褦��
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
