#lang racket/base

(require scribble/eval)
(require scribble/base)
(require racket/sandbox)
(require mzlib/pconvert)
(require racket/pretty)
(require file/convertible)
(require 2htdp/image)
(require scribble/manual)
(require teachpack/2htdp/scribblings/img-eval)

(provide block ev ex vdash stdeval bsl-eval asl-eval todo step multistep equiv prime e e0 e1 e2 e3 e4 eN-1 eN v v1 v2 v3 vN-1 vN x x1 x2 x3 xI xN-1 xN xN eI vI eI-1 eI+1)


(define step (elem "→")) ; (bitmap "arrow.png"))
(define vdash (elem "⊢")) ; (bitmap "arrow.png"))

(define multistep (elem step (superscript "*")))
(define equiv (elem "≡"))

(define e (italic "e"))
(define e0 (elem e (subscript "0")))
(define e1 (elem e (subscript "1")))
(define e2 (elem e (subscript "2")))
(define eI-1 (elem e (subscript "i-1")))
(define eI+1 (elem e (subscript "i+1")))
(define e3 (elem e (subscript "3")))
(define e4 (elem e (subscript "4")))
(define eI (elem e (subscript "i")))
(define eN-1 (elem e (subscript "n-1")))
(define eN (elem e (subscript "n")))

(define v (italic "v"))
(define v1 (elem v (subscript "1")))
(define v2 (elem v (subscript "2")))
(define v3 (elem v (subscript "3")))
(define vI (elem v (subscript "i")))
(define vN-1 (elem v (subscript "n-1")))
(define vN (elem v (subscript "n")))
(define x (italic "x"))
(define x1 (elem x (subscript "1")))
(define x2 (elem x (subscript "2")))
(define x3 (elem x (subscript "3")))
(define xI (elem x (subscript "i")))
(define xN-1 (elem x (subscript "n-1")))
(define xN (elem x (subscript "n")))


(define (prime x) (elem x "'"))

(define (todo text)
  '())

(define stdeval (isl-eval+))

(void (interaction-eval #:eval stdeval (require 2htdp/image)))
(void (interaction-eval #:eval stdeval (define rocket (bitmap "rocket-s.jpg"))))


(define-syntax block
  (syntax-rules ()
    [(_ e ...)
     (racketblock+eval #:eval stdeval #:escape unsyntax e ...)]))

(define-syntax ev
  (syntax-rules ()
    [(_ e )
     (interaction-eval-show #:eval stdeval e)]))

(define-syntax ex
  (syntax-rules ()
    [(_ e ...)
       (interaction #:eval stdeval e ...)]))


(define-syntax-rule
  (*sl-eval module-lang reader def ...)
  ;; ===>>>
  (let ()
    (define me (parameterize ([sandbox-propagate-exceptions #f])
                 (make-img-eval)))
    (me '(require (only-in racket empty? first rest cons? sqr true false)))
    (me '(require lang/posn))
    (me '(require racket/pretty))
    (me '(current-print pretty-print-handler))
    (me '(pretty-print-columns 65))
    (me 'def)
    ...
    (call-in-sandbox-context me (lambda () (error-print-source-location #f)))
    (call-in-sandbox-context me (lambda () (sandbox-output 'string)))
    (call-in-sandbox-context me (lambda () (sandbox-error-output 'string)))
    (call-in-sandbox-context me (lambda () (sandbox-propagate-exceptions #f)))
    (call-in-sandbox-context me (lambda ()
				  (current-print-convert-hook
				    (let ([prev (current-print-convert-hook)])
				      ;; tell `print-convert' to leave images as themselves:
				      (lambda (v basic sub)
					(if (convertible? v)
					    v
					    (prev v basic sub)))))

				  (pretty-print-size-hook
				    (let ([prev (pretty-print-size-hook)])
				      ;; tell `pretty-print' that we'll handle images specially:
				      (lambda (v w? op)
					(if (convertible? v) 1 (prev v w? op)))))
				  
				  (pretty-print-print-hook
				    (let ([prev (pretty-print-print-hook)])
				      ;; tell `pretty-print' how to handle images, which is
				      ;; by using `write-special':
				      (lambda (v w? op)
					(if (convertible? v) (write-special v op) (prev v w? op)))))

				  ((dynamic-require 'htdp/bsl/runtime 'configure)
				   (dynamic-require reader 'options))))
    (call-in-sandbox-context me (lambda () (namespace-require module-lang)))
    (interaction-eval #:eval me (require 2htdp/image))
    (interaction-eval #:eval me (require 2htdp/batch-io))
    (error-display-handler
     (lambda (msg exn)
       (if (exn? exn)
           (display (get-rewriten-error-message exn) (current-error-port))
           (eprintf "uncaught exception: ~e" exn))))
    me))

(require lang/private/rewrite-error-message)
	
(define-syntax-rule
  (bsl-eval def ...)
  (*sl-eval 'lang/htdp-beginner 'htdp/bsl/lang/reader def ...))

(define-syntax-rule
  (bsl-eval+ def ...)
  (*sl-eval 'lang/htdp-beginner-abbr 'htdp/bsl+/lang/reader def ...))

(define-syntax-rule
  (isl-eval def ...)
  (*sl-eval 'lang/htdp-intermediate 'htdp/isl/lang/reader def ...))

(define-syntax-rule 
  (isl-eval+ def ...)
  (*sl-eval 'lang/htdp-intermediate-lambda 'htdp/isl/lang/reader def ...))


(define-syntax-rule 
  (asl-eval def ...)
  (*sl-eval 'lang/htdp-advanced 'htdp/asl/lang/reader def ...))

