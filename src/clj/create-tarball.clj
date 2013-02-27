(ns foo
  (:import [org.apache.commons.compress.archivers.tar TarArchiveEntry TarArchiveOutputStream]
           [org.apache.commons.compress.compressors.gzip GzipCompressorOutputStream])
  (:use    [clojure.java.io]))

(let [filestream  (java.io.FileOutputStream. "/home/cprice/work/puppetdb/scratch/commons-compress/test.tar.gz")
      gzipstream (GzipCompressorOutputStream. filestream)
      tarstream (TarArchiveOutputStream. gzipstream)
      archive-entry (TarArchiveEntry. "foo/bar.txt")
      archive-contents "Hello\nWorld"
      archive-writer (writer tarstream)]
  (.setSize archive-entry (count archive-contents))
;  (.setUserId archive-entry 0)
;  (.setGroupId archive-entry 0)
;  (.setModTime archive-entry 0)
;  (.setUserName archive-entry "foo")
;  (.setGroupName archive-entry "foo")
;  (.setMode archive-entry 0100000)
  (.putArchiveEntry tarstream archive-entry)
  (.write archive-writer archive-contents)
  (.flush archive-writer)
  (.closeArchiveEntry tarstream)
  (.close tarstream)
  (.close gzipstream))


