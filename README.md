# Web Filtering Database client for Dart

`webfilteringdatabase` classifies a domain or URL into a web filtering category, the kind a DNS resolver, secure web gateway or school filter uses to decide allow or block. It calls the classification endpoint of the [web filter lookup](https://www.webfilteringdatabase.com/check-domain.php) service and hands the JSON back to your Dart code.

```bash
dart pub add webfilteringdatabase
```

```dart
import 'package:webfilteringdatabase/webfilteringdatabase.dart';

final wf = WebFilteringDatabaseClient(apiKey: key);
final r = await wf.classify('example.com');
print(r.toJson());
wf.close();
```

The rest of this page is organised as the questions people ask when they build a filter around it.

## What is the difference between this and the downloadable database?

The database is a licensed file you load into your resolver or gateway. Lookups against it are local, instant and free of per-call cost, which is what you want for the traffic you see every day.

This package is for the domains the file does not have yet. New registrations, fresh campaign sites and obscure hosts all show up in real traffic before they show up in any list. Calling `classify` on a miss gives you a category right away, so the policy has something to act on.

## What does a response contain?

The main field is the filtering category, with a confidence value. Depending on the request, the service can also return the root domain it evaluated and the method used to reach the answer. The field reference is published in the API documentation on the website. The client returns the JSON unchanged in an `ApiResult`, which you read with `r['field']` or convert with `toJson()`.

## Where should the call sit in a resolver?

After the local lookup and before the default action. A sketch:

```dart
Future<String> categoryFor(String host) async {
  final local = localDb[host];
  if (local != null) return local;
  try {
    final r = await wf.classify(host);
    final cat = r['web_filtering_category'] as String?;
    if (cat != null) localDb[host] = cat; // remember it
    return cat ?? 'unknown';
  } on ApiException {
    return 'unknown';
  }
}
```

Two rules keep a resolver healthy:

1. **Never block the DNS answer on a slow call.** Serve the default action for this query and let the classification land in the cache for the next one.
2. **Decide what `unknown` means.** A school network may block unknown domains. An office network usually allows them and logs them.

## How fast is it, and how do I set timeouts?

A classification involves looking at the site, so it is slower than a local match. The default timeout is 30 seconds. On a hot path, set a shorter one and treat a timeout as `unknown`:

```dart
final wf = WebFilteringDatabaseClient(
  apiKey: key,
  timeout: const Duration(seconds: 5),
);
```

A timeout surfaces as `TimeoutException` from `dart:async`.

## What errors can I expect?

- `AuthenticationException`: HTTP 401 or 403. The key is wrong, or the plan's quota for the month is used.
- `RateLimitException`: HTTP 429. Too many calls too quickly.
- `ApiException`: any other HTTP failure, or a reply that is not a JSON object. `statusCode` and `body` hold the details.
- `ArgumentError`: empty key or empty input, raised before anything is sent.

The client does not retry. Most filters are better off caching `unknown` for a few minutes than hammering the service.

## Can I use it for school filtering?

Yes. Schools in the United States that take E-rate funding must filter under the Children's Internet Protection Act (CIPA), and many districts elsewhere follow similar rules. Categories such as adult content, gambling, weapons and proxies map directly onto those policies. A district filter typically blocks those categories outright and sends everything else through normal logging.

Generative AI deserves its own decision in schools. Some districts block AI chat during exams and allow it at other times. To [block AI tools during exams](https://www.aitoolsblocklist.com/education-ai-filtering.php) rather than site by site, add the dedicated AI register as a second source.

## How should an MSP structure this across many clients?

Keep one shared cache of classifications and separate policies per client. The category of a domain does not depend on who asks, but the action does. A law firm may block file sharing while a design agency needs it. Store `domain → category` once, then map `client + category → action` in a small table each client can change. A new client then starts with a warm cache on day one.

## What about subdomains and shared hosting?

Classify at the level where the content differs. For most companies the registered domain is enough. For hosting platforms, blog networks and cloud storage, one parent domain holds many unrelated sites, so pass the full hostname or URL. A filter that decides on `example-host.com` alone would treat every customer site on that host the same.

## How do I test code that uses the client?

Swap in a `MockClient`:

```dart
final wf = WebFilteringDatabaseClient(
  apiKey: 'test',
  httpClient: MockClient((_) async =>
      http.Response('{"web_filtering_category":"News"}', 200)),
);
```

Or point `baseUrl` at a local stub server that returns canned replies.

## Does the client send my users' browsing data?

It sends only what you pass to `classify`: one domain or URL per call, plus your key. It sends no client IP, username or device ID. If you pass full URLs, consider stripping query strings first. They can carry session tokens and personal data, and the domain alone is usually enough to classify.

## What else is useful alongside it?

- For a view of which AI apps people use, [a sample shadow AI audit](https://www.shadowaitools.com/sample-report.php) works from the same DNS logs a filter already keeps.
- For topic categories aimed at advertising and analytics, the [domain classification API](https://www.websitecategorizationapi.com/api-docs.php) uses the IAB taxonomy.

## Is there a version for other languages?

- [npm: webfilteringdatabase](https://www.npmjs.com/package/webfilteringdatabase)
- [Rust crate: webfilteringdatabase](https://crates.io/crates/webfilteringdatabase)
- [PHP: webfilteringdatabase on Packagist](https://packagist.org/packages/webfilteringdatabase/webfilteringdatabase)

## License

MIT
