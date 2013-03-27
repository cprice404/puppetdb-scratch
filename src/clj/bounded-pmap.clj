(ns foo
  (:require [clojure.tools.logging :as log])
  (:import  [java.util.concurrent Executors Executor TimeUnit FutureTask]
            [java.io Closeable]
            [org.apache.log4j Logger ConsoleAppender PatternLayout Level]))

;(.addAppender (Logger/getRootLogger)
;  (let [layout (PatternLayout. "%d %-5p [%t] [%c{2}] %m%n")]
;    (doto (ConsoleAppender.)
;      (.setLayout layout)
;      (.setThreshold Level/DEBUG)
;      (.activateOptions))))

(defn agent-foo
  []
  (let [agents (transient [])]
    (doseq [i (range 25)]
      (let [myagent (agent true)]
        (conj! agents myagent)
        (send myagent (fn [_] (do (log/info "agent" i "sleeping") (Thread/sleep 2000) (log/info "agent" i "done")))))                                                                  )
    (doseq [myagent (persistent! agents)]
      (log/info "Waiting for agent")
      (await myagent))))

;(defn run-with-agent
;  [f & args]
;  (let [myagent (agent true)]
;    (send myagent (fn [_] (apply f args)))
;    (await myagent)
;    (println "about to deref agent:" @myagent)
;    (println "errors:" (agent-error myagent))
;    @myagent))
;
;(defmacro run-with-agent
;  [& body]
;  `(let [myagent# (agent true)]
;    (println "About to send to agent")
;    (send myagent# (fn [_#] ~@body))
;    (await myagent#)
;    (println "about to deref agent:" @myagent#)
;    (println "errors:" (agent-error myagent#))
;    @myagent#))
;
;(run-with-agent (+ 1 2))
;(run-with-agent (throw (IllegalArgumentException. "hi")))


;(defn pmap-with-pool-size
;  [pool-size f coll]
;  (let [executor   (Executors/newFixedThreadPool pool-size)
;        wrapped-fn (wrap-with-java-future executor f)]
;    (pmap wrapped-fn coll)))


;(let [f #(sleep-and-do (println %))]
;  (f 1)
;  (f 2)
;  (f 3))

;(doall (pmap-with-pool-size 5 #(sleep-and-do (log/info %)) (range 20)))
;(log/info "DONE!")
;(println "DONE DONE!")

(defmacro sleep-and-do
  [& body]
  `(do
;      (log/info "About to sleep")
      (Thread/sleep 2000)
;      (log/info "done sleeping, execute body")
      ~@body))

;(sleep-and-do (println "hi"))

(defn wrap-with-java-future
  [pool f]
  (fn [item]
    (let [java-future (FutureTask. #(f item))]
      (log/info "Created future for" item ":" java-future)
      (.execute pool java-future)
      (.get java-future))))


(deftype ThreadPool [executor]
  Executor
  (execute [this runnable]
    (log/info "#execute")
    (.execute executor runnable))

  Closeable
  (close [this]
;    (throw (IllegalStateException. "JUST WANNA SEE THE STACK!"))
    (log/info "#close")
    (.shutdown executor)
    (log/info "Called shutdown")
    (.awaitTermination executor Long/MAX_VALUE TimeUnit/DAYS)
    (log/info "Back from awaitTermination")))

(defn thread-pool
  [pool-size]
  (log/info "Creating thread pool with size:" pool-size)
  (ThreadPool. (Executors/newFixedThreadPool pool-size)))

(defn pmap-with-pool
  [pool f coll]
  (let [wrapped-fn (wrap-with-java-future pool f)]
    (pmap wrapped-fn coll)))

;(thread-pool 5)

;(with-open [pool (thread-pool 5)]
;  (log/info "hi"))

;(with-open [pool (thread-pool 5)]
;  (doall (pmap-with-pool pool #(sleep-and-do (log/info %)) (range 20)))
;  (log/info "DONE!")
;  (println "DONE DONE!"))

(with-open [pool (thread-pool 5)]
  (doall (pmap-with-pool pool #(log/info %) (range 20)))
  (log/info "DONE!")
  (println "DONE DONE!"))

