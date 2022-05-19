load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def github_archive(name, user = None, repo = None, commit = None, **kwargs):
    repo = repo or name

    http_archive(
        name = name,
        strip_prefix = "{}-{}".format(repo, commit),
        url = "https://github.com/{}/{}/archive/{}.tar.gz".format(user, repo, commit),
        **kwargs
    )
