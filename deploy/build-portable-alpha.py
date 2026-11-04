#!/usr/bin/env python3
"""Build a complete minimal %harbor-alpha desk from explicit public files."""
import argparse, hashlib, ipaddress, json, re, sys
from pathlib import Path

R = Path(__file__).resolve().parents[1]
SHIP_RE = re.compile(r'~(?:[a-z]{3}|[a-z]{6}(?:-{1,2}[a-z]{6}){0,7})')
LIBS = ['harbor-octra-public', 'harbor-octra-auth', 'harbor-octra-packet',
        'harbor-alpha-import', 'harbor-alpha-outbox', 'harbor-alpha-core',
        'harbor-alpha-json', 'harbor-alpha-network', 'harbor-alpha-profile-json']
BASE = ['mar/noun.hoon', 'mar/hoon.hoon', 'mar/txt.hoon', 'mar/kelvin.hoon',
        'mar/bill.hoon', 'mar/mime.hoon', 'mar/json.hoon', 'lib/skeleton.hoon',
        'lib/default-agent.hoon', 'lib/dbug.hoon', 'lib/server.hoon', 'sys.kelvin']
WEB = [('index.hoon', 'public-alpha/index.html'), ('app.hoon', 'public-alpha/app.mjs'),
       ('alpha-view.hoon', 'public-alpha/alpha-view.mjs'),
       ('network-picker.hoon', 'public-alpha/network-picker.mjs'),
       ('pin-client.hoon', 'public/pin-client.mjs')]
NOTICES = [('LICENSE', 'license.txt'), ('integrations/distribution-notices/URBIT-LICENSE.txt', 'notices/urbit.txt'),
           ('integrations/distribution-notices/OCTRA-COPYING', 'notices/octra.txt'),
           ('integrations/distribution-notices/GPL-2.0.txt', 'notices/gpl-2.txt')]
STYLE = '\n#import,#send{display:grid;gap:14px}textarea{min-height:90px;max-width:100%;font:inherit}input{min-width:0}#view .row{overflow-wrap:anywhere}#view .panel{display:grid;gap:18px}\n'
README = ('# harbor-alpha portable desk\n\n'
          'Launch /harbor-alpha/ after manual desk install. Mainnet only by default; '
          'devnet requires a local gateway. No wallet generation. PIN is not 2FA or key encryption. '
          'The host and all installed local Gall apps can access plaintext saved signing keys. '
          'The minimal desk was tested on two isolated fake ships and a fresh real moon, including restart. One small funded mainnet payment and a funded devnet payment were confirmed separately on the test moon, with restart persistence. '
          'Third-party notices are included under notices/. Harbor original contributions are GPL-2.0-or-later; see license.txt and the preserved upstream notices. Experimental alpha; not audited custody software.\n')


def fail(msg):
    sys.exit('build-portable-alpha: ' + msg)


def no_symlink_ancestors(p, label):
    for a in [p, *p.parents]:
        if a.is_symlink():
            fail(label + ' has a symlink ancestor: ' + str(a))


def clean(p, label):
    no_symlink_ancestors(p, label)
    if p.is_symlink():
        fail(label + ' is a symlink: ' + str(p))
    if not p.is_file():
        fail(label + ' missing: ' + str(p))
    return p


def inside(root, p):
    try:
        p.relative_to(root)
    except ValueError:
        fail('escapes ' + str(root) + ': ' + str(p))


def origin_host(origin):
    # Accept only canonicalizable HTTPS DNS/IPv4 origins, not arbitrary Hoon text.
    match = re.fullmatch(r'https://([A-Za-z0-9.-]+)(?::([0-9]{1,5}))?/?', origin)
    if not match:
        fail('origin must be an HTTPS DNS/IPv4 origin with optional port')
    host = match[1].lower()
    if len(host) > 253 or any(not re.fullmatch(r'[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?', x) for x in host.split('.')):
        fail('invalid origin hostname')
    if re.fullmatch(r'[0-9.]+', host):
        try:
            ipaddress.IPv4Address(host)
        except ValueError:
            fail('invalid IPv4 address')
    port = int(match[2]) if match[2] else 443
    if not 1 <= port <= 65535:
        fail('port must be 1..65535')
    authority = host + (':' + str(port) if port != 443 else '')
    return 'https://' + authority, authority


def config_text(ship, origin, host, devnet):
    return ('|%\n++  desk  %harbor-alpha\n'
            "++  ship  " + ship + "\n"
            "++  origin  '" + origin + "'\n"
            "++  host  '" + host + "'\n"
            "++  mainnet-endpoint  'https://octra.network/rpc'\n"
            "++  devnet-endpoint  'http://127.0.0.1:18840/rpc'\n"
            '++  devnet-enabled  ' + ('&' if devnet else '|') + '\n'
            '--\n')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--ship', required=True)
    ap.add_argument('--origin', required=True)
    ap.add_argument('--base-source', default=str(R / 'vendor/urbit-base'))
    ap.add_argument('--output', required=True)
    ap.add_argument('--enable-devnet', action='store_true', default=False)
    a = ap.parse_args()

    if not SHIP_RE.fullmatch(a.ship):
        fail('bad ship token: ' + a.ship)
    origin, host = origin_host(a.origin)
    base = Path(a.base_source).absolute()
    out = Path(a.output).absolute()
    no_symlink_ancestors(base, 'base source')
    no_symlink_ancestors(out, 'output')
    base = base.resolve()
    out = out.resolve()
    if not out.parent.is_dir():
        fail('output parent directory must exist')
    if out.exists():
        fail('output already exists: ' + str(out))

    app_src = clean(R / 'desk/app/harbor-alpha.hoon', 'app')
    if 'cf=harbor-alpha-config' not in app_src.read_text():
        fail('app missing cf=harbor-alpha-config')
    lib_srcs = [clean(R / 'desk/lib' / (n + '.hoon'), 'lib ' + n) for n in LIBS]
    base_srcs = [clean(base / rel, 'base ' + rel) for rel in BASE]
    web_srcs = [clean(R / rel, 'web ' + rel) for _, rel in WEB]
    style_src = clean(R / 'public/style.css', 'style')
    notice_srcs = [clean(R / rel, 'notice ' + rel) for rel, _ in NOTICES]

    for p in [app_src, *lib_srcs, *base_srcs, *web_srcs, *notice_srcs, style_src]:
        inside(R if R in p.parents else base, p.resolve())

    plan = {'app/harbor-alpha.hoon': app_src.read_bytes(),
            'lib/harbor-alpha-config.hoon': config_text(a.ship, origin, host, a.enable_devnet).encode(),
            'desk.bill': b'~[%harbor-alpha]\n',
            'readme.txt': README.encode()}
    for n, p in zip(LIBS, lib_srcs):
        plan['lib/' + n + '.hoon'] = p.read_bytes()
    for rel, p in zip(BASE, base_srcs):
        plan[rel] = p.read_bytes()
    for name, p in zip([w[0] for w in WEB], web_srcs):
        plan['web/harbor-alpha/' + name] = p.read_bytes()
    plan['web/harbor-alpha/style.hoon'] = style_src.read_bytes() + STYLE.encode()
    for dest, p in zip([d for _, d in NOTICES], notice_srcs):
        plan[dest] = p.read_bytes()

    out.mkdir()
    for rel, data in sorted(plan.items()):
        dest = out / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        with dest.open('xb') as stream:
            stream.write(data)
    manifest = {rel: {'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}
                for rel, data in sorted(plan.items())}
    with (out / 'manifest.json').open('x') as stream:
        stream.write(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
    print('built ' + str(out) + ' with ' + str(len(plan) + 1) + ' files')


if __name__ == '__main__':
    main()
