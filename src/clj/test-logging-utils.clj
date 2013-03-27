(ns foo
  (:use com.puppetlabs.testutils.logging
        clojure.tools.logging))

(with-log-output logs
  (info "Hello There")
  (println "type:" (type @logs))
  (println (logs-matching #"Hello" @logs)))
