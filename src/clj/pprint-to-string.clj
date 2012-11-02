    (import java.io.StringWriter)
    (use '[clojure.pprint :only (pprint)])
    (log/info (format "RECEIVED REPORT SUBMISSION:\n%s\n\n"
                (let [writer (java.io.StringWriter.)]
                  (clojure.pprint/pprint event-group writer)
                  (.toString writer))))
