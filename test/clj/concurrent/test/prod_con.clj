(ns concurrent.test.prod-con
  (:use clojure.test
        concurrent.prod-con)
  (:require [clojure.tools.logging :as log]))

(defn swap-and-return-old-val!
  [a f & args]
  (loop []
    (let [old-value @a
          new-value (apply f old-value args)]
      (if (compare-and-set! a old-value new-value)
        old-value
        (recur)))))

(defn simple-work-stack
  [size]
  {:pre  [(pos? size)]}
  (let [original-work   (range size)
        remaining-work  (atom (range size))
        counter         (atom 0)
        iterator-fn     (fn []
                          (swap! counter inc)
                          (let [old-work  (swap-and-return-old-val! remaining-work next)
                                next-item (first old-work)]
;                            (log/info "iterator-fn called (count" @counter "), returning" next-item)
                            next-item))]
    {:original-work   original-work
     :remaining-work  remaining-work
     :counter         counter
     :iterator-fn     iterator-fn}))

(deftest test-iterator-fn->lazy-seq
  (let [{:keys [counter iterator-fn]} (simple-work-stack 5)
        iterator-seq                  (iterator-fn->lazy-seq iterator-fn)]
    (testing "iterator-fn is not called until seq is accessed"
      (is (= 0 @counter)))
    (testing "iterator-fn is called exactly once if we take one item from the seq"
      (is (= 0 (first iterator-seq)))
      (is (= 1 @counter)))
    (testing "iterator-fn is not called again if we take the same item from the seq again"
      (is (= 0 (first iterator-seq)))
      (is (= 1 @counter)))
    (testing "iterator-fn is called one more time if we take the first two items from the seq"
      (is (= '(0 1) (take 2 iterator-seq)))
      (is (= 2 @counter)))
    (testing "iterator-fn is called once for each item in the seq, plus once for the final nil if we walk the whole seq"
      (doseq [i iterator-seq] i)
      (is (= 6 @counter)))))

(deftest test-work-queue->seq
  (let [queue (work-queue)]
    (doseq [i (range 5)]
      (.put queue i))
    (.put queue work-complete-sentinel)
    (let [queue-seq  (work-queue->seq queue)]
      (is (= (range 5) queue-seq)))))

(deftest test-producer
  (doseq [num-workers [1 2 5]
          max-work    [0 2 10]]
    (testing (format "with %d worker(s) and %d max work items" num-workers max-work)
      (let [num-work-items                5
            {:keys [counter iterator-fn
                    original-work]}       (simple-work-stack num-work-items)
            p                             (producer iterator-fn num-workers max-work)
            {:keys [workers work-queue]}  p
            queued-work                   (work-queue->seq work-queue)]
        (testing "number of workers matches what we requested"
          (is (= num-workers (count workers))))
        (testing "work queue contains the correct work items"
          (is (= (set original-work) (set queued-work))))
        (testing "workers completed the correct number of work items"
          (let [work-completed (apply + (map deref workers))]
            (is (= num-work-items work-completed))))))))

(deftest test-consumer
  (doseq [num-workers [1 2 5]
          max-work    [0 2 10]]
    (testing (format "with %d worker(s) and %d max work items" num-workers max-work)
      (let [num-work-items                    5
            {:keys [counter iterator-fn
                    original-work]}           (simple-work-stack num-work-items)
            p                                 (producer iterator-fn num-workers max-work)
            {:keys [workers result-queue]}    (consumer p inc num-workers max-work)
            queued-results                    (work-queue->seq result-queue)]
        (testing "number of workers matches what we requested"
          (is (= num-workers (count workers))))
        (testing "result queue contains the correct results"
          (is (= (set (map inc original-work)) (set queued-results))))
        (testing "workers completed the correct number of work items"
          (let [work-completed (apply + (map deref workers))]
            (is (= num-work-items work-completed))))))))
