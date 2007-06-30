(in-package #:cl-markdown)

(defun next-block (chunks level)
  (let* (;; the first chunk after the current one with a lower level
         (pos-level (position-if 
                     (lambda (other)
		       (< (level other) level))
                     (rest chunks)))
         ;; the first chunk after the current one with different markup
	 ;; and level less than or equal to
        (pos-markup (position-if 
                      (lambda (other)
			(and (<= (level other) level)
			     (not (samep (markup-class other) 
					 (markup-class (first chunks))))))
                      (rest chunks)))
         pos-style
         deeper)
    #+Ignore
    (format t "~%~d ~2,D:POS: ~A, ~A - ~A" 
            level (length chunks) pos-level pos-markup (first chunks))
    ;; remember that there will be another call to rest 
    (cond ((null pos-level)
           ;; go all the way to the end
           (setf deeper (subseq chunks 0)
                 chunks nil
                 pos-style :rest))
          ((or (and pos-level pos-markup (> pos-level pos-markup))
               (and pos-level (not pos-markup)))
	   ;(format t " -- level")
	   (setf deeper (subseq chunks 0 (1+ pos-level))
                 chunks (nthcdr pos-level chunks)
                 pos-style :level))
          ((or (and pos-level pos-markup (> pos-markup pos-level))
               (and (not pos-level) pos-markup))
	   ;(format t " -- markup")
           (setf deeper (subseq chunks 0 (+ pos-markup 2))
                 chunks (nthcdr (1+ pos-markup) chunks)
                 pos-style :markup))
          ((and pos-level pos-markup (= pos-level pos-markup))
	   ;(format t " -- level")	   
           (setf deeper (subseq chunks 0 (1+ pos-level))
                 chunks (nthcdr pos-level chunks)
                 pos-style :level))
          (t
           ;; nothing found, take the rest
           (setf deeper chunks 
                 chunks nil
                 pos-style :none)))
    ;(format t "~{~%    ~a~}" (collect-elements deeper))
    (values deeper chunks pos-style)))

(defmethod render-to-stream (document style stream-specifier)
  (with-stream-from-specifier (stream stream-specifier :output 
				      :if-exists :supersede)
    (let ((*current-document* document)
          (*current-format* style)
          (*output-stream* stream))
      (setf (level document) 0
            (markup document) nil)
      (render document style stream))))
  
(defun ensure-string (it)
  (typecase it
    (string it)
    (symbol (symbol-name it))
    (t (format nil "~a" it))))

(defun collect-links (document)
  (collect-key-value (link-info document)
		     :transform (lambda (name link)
				  (cons name (url link)))
		     :filter (lambda (k v)
			       (declare (ignore k))
			       (typep v 'link-info))))

(defun starts-with (string prefix)
  (let ((mismatch (mismatch prefix string)))
    (or (not mismatch) (= mismatch (length prefix)))))
