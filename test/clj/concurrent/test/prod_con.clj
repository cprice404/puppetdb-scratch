(ns concurrent.test.prod-con
  (:use clojure.test
        concurrent.prod-con))

(defn simple-work-stack
  [size]
  {:pre  [(pos? size)]}
  (let [original-work   (range size)
        remaining-work  (atom (range size))
        counter         (atom 0)
        iterator-fn     (fn []
                          (swap! counter inc)
                          (let [next-item (first @remaining-work)]
                            (swap! remaining-work next)
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
  (testing "with a single worker"
    (let [{:keys [counter iterator-fn
                  original-work]} (simple-work-stack 5)
          p                       (producer iterator-fn 1)
          {:keys [workers queued-work]} p]
        (testing "number of workers matches what we requested"
          (is (= 1 (count workers))))
        (testing "worker completed the correct number of work items"
          (let [worker (first workers)]
            (is (= 5 @worker))))
        (testing "work queue contains the correct work items"
          (is (= original-work queued-work))))))