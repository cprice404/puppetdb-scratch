(ns concurrent.prod-con
  (:require [clojure.tools.logging :as log])
  (:import  [java.util.concurrent BlockingQueue ArrayBlockingQueue LinkedBlockingQueue]))

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

(defn- build-worker
  ;; TODO docs
  [work-seq-fn enqueue-fn]
  (future
    (let [work-count (atom 0)]
      (doseq [work (work-seq-fn)]
        (enqueue-fn work)
        (swap! work-count inc))
      @work-count)))

(gen-interface
  :name    concurrent.prod-con.MinimalBlockingQueue
  :methods [[take []       Object]
            [put  [Object] void]])

(deftype WorkQueue [queue]
  concurrent.prod-con.MinimalBlockingQueue
  (put [this item]
    (.put queue item))
  (take [this]
    (.take queue)))

(defrecord Producer     [workers work-queue])
(defrecord Consumer     [workers result-queue])

(defn work-queue
  ;; TODO docs
  ([] (work-queue 0))
  ([size]
   {:pre  [(>= size 0)]
    :post [(instance? WorkQueue %)]}
   (if (= 0 size)
      (WorkQueue. (LinkedBlockingQueue.))
      (WorkQueue. (ArrayBlockingQueue. size)))))

;; TODO docs
(def work-complete-sentinel (Object.))

(defn work-queue->seq
  ;; TODO docs
  [queue]
  {:pre  [(instance? WorkQueue queue)]
   :post [(seq? %)]}
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
    {:pre  [(fn? work-fn)
            (pos? num-workers)
            (>= max-work 0)]
     :post [(instance? Producer %)
            (instance? WorkQueue (:work-queue %))
            (every? future? (:workers %))]}
    (let [queue       (work-queue max-work)
          workers     (doall (for [_ (range num-workers)]
                        (build-worker
                          #(iterator-fn->lazy-seq work-fn)
                          #(.put queue %))))
          supervisor  (future
                        ;; TODO: doc
                        (doseq [worker workers] @worker)
                        (.put queue work-complete-sentinel))]
      (Producer. workers queue))))

(defn consumer
  ;; TODO: docs preconds
  ([producer work-fn num-workers] (consumer producer work-fn num-workers 0))
  ([{producer-queue :work-queue :as producer} work-fn num-workers max-results]
   {:pre  [(instance? Producer producer)
           (instance? WorkQueue producer-queue)]
    :post [(instance? Consumer %)
           (instance? WorkQueue (:result-queue %))
           (every? future? (:workers %))]}
   (let [result-queue   (work-queue max-results)
         workers        (doall (for [_ (range num-workers)]
                           (build-worker
                             #(work-queue->seq producer-queue)
                             #(.put result-queue (work-fn %)))))
         supervisor     (future
                          ;; TODO: doc
                          (doseq [worker workers] @worker)
                          (.put result-queue work-complete-sentinel))]
    (Consumer. workers result-queue))))
