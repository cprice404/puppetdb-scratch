(ns concurrent.prod-con
  (:require [clojure.tools.logging :as log]))

;; TODO:  put in general namespace
(defn iterator-fn->lazy-seq
  ;; TODO docs
  [f]
  {:pre  [(fn? f)]
   :post [(seq? %)]}
  (lazy-seq
    (let [next-item (f)]
      (if (nil? next-item)
        '()
        (cons next-item (iterator-fn->lazy-seq f))))))

(defn work-queue
  ;; TODO docs
  ([] (work-queue 0))
  ([size]
   (if (= 0 size)
      (java.util.concurrent.LinkedBlockingQueue.)
      (java.util.concurrent.ArrayBlockingQueue. size))))

;; TODO docs
(def work-complete-sentinel (Object.))

(defn work-queue->seq
  ;; TODO docs
  [queue]
  {:pre  [(instance? java.util.concurrent.BlockingQueue queue)]}
  (iterator-fn->lazy-seq
    (fn []
      (let [next-item (.take queue)]
        (if (= work-complete-sentinel next-item)
          (do
            ;; TODO: doc
            (.put queue work-complete-sentinel)
            nil)
          next-item)))))

(defn producer
  ;; TODO: docs preconds
  ([work-fn num-workers]
    (producer work-fn num-workers 0))
  ([work-fn num-workers max-work]
    (let [queue       (work-queue max-work)
          workers     (doall (for [_ (range num-workers)]
                        (future
                          (let [work-count (atom 0)]
                            (doseq [work (iterator-fn->lazy-seq work-fn)]
                              (.put queue work)
                              (swap! work-count inc))
                            @work-count))))
          supervisor  (future
                        ;; TODO: doc
                        (doseq [worker workers] @worker)
                        (.put queue work-complete-sentinel))]
      {:work-queue  queue
       :workers     workers})))

(defn consumer
  ;; TODO: docs preconds
  ([producer work-fn num-workers] (consumer producer work-fn num-workers 0))
  ([{producer-queue :work-queue :as producer} work-fn num-workers max-results]
   {:pre  [(instance? java.util.concurrent.BlockingQueue producer-queue)]}
   (let [result-queue   (work-queue max-results)
         workers        (doall (for [_ (range num-workers)]
                          (future
                            (let [work-count  (atom 0)
                                  work-seq    (work-queue->seq producer-queue)]
                              (doseq [work work-seq]
                                (.put result-queue (work-fn work))
                                (swap! work-count inc))
                              @work-count))))
       supervisor     (future
                        ;; TODO: doc
                        (doseq [worker workers] @worker)
                        (.put result-queue work-complete-sentinel))]
    {:result-queue  result-queue
     :workers       workers})))
