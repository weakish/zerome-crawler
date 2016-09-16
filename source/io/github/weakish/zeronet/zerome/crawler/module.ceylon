"""A module to crawl zerome hubs.

   Given hub A and B, we say A links to B
   iff there exists a user in A follows any user in B.

   To crawl a hub for links to other hubs:

   ```ceylon
   // Assuming the current directory is zeronet data dir (`zeronet.py --data_dir`).
   Hub hub = crawl("HUB_ID");
   ```

   To crawl a **hub** in `/path/to/data/dir` recursively (also crawl hubs **hub** links to):

   ```ceylon
   Hubs hubs = crawl("HUB_ID", parsePath("/path/to/data/dir"),
   ```

   Only one level of recursion is supported.
   And hubs you are not seeding will be skipped.

   `Hub` is an `Entry`, and `Hubs` is a `Set<Hub>`,
   for accurate definition, see the aliases section below.

   This module can also be used as a command line tool.

   For example, assuming current directory is ZeroNet `data` direcotry,
   crawl RedHub:

   ```sh
   java -jar zerome-crawler.jar --hub 1RedkCkVaXuVXrqCMpoXQS29bwaqsuFdL
   ```

   List all hubs where at least one user has registered.

   ```sh
   java -jar zerome-crawler.jar --all --list-only
   ```

   Crawl all hubs, the data dir is `/var/zeronet/data`:

   ```sh
   java -jar zerome-crawler.jar --all --data_dir /var/zeronet/data
   ```
   """
by("Jakukyo Friel")
license("0BSD")
native ("jvm")
module io.github.weakish.zeronet.zerome.crawler "0.0.0" {
    shared import ceylon.file "1.2.2";
    shared import ceylon.json "1.2.2";
    shared import ceylon.collection "1.2.2";
    import ceylon.logging "1.2.2";
    import ceylon.test "1.2.2";
    shared import java.base "7";
}
