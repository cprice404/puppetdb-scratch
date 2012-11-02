(ns createbroker
  (:require [com.puppetlabs.mq :as mq]))

(let [foo (mq/build-embedded-broker "/home/cprice/work/puppetdb/scratch/temp-msg-broker-dir")]
  (println "hi")
  (println foo)
  (println "bye"))
