<h1 align="center">🚀 Headless Telemt for OpenWrt</h1>

<p align="center">
  Lightweight <b>telemt</b> binary packages for OpenWrt<br/>
  <i>Built from the official <code>telemt/telemt</code> repository and adapted for real OpenWrt deployment</i>
</p>

<p align="center">
  <a href="#overview">Overview</a> •
  <a href="#whats-included">What’s included</a> •
  <a href="#why-this-build-exists">Why this build exists</a> •
  <a href="#build-pipeline">Build pipeline</a> •
  <a href="#openwrt-specific-work">OpenWrt-specific work</a> •
  <a href="#packages">Packages</a> •
  <a href="#installation">Installation</a> •
  <a href="#notes">Notes</a>
</p>

<hr/>

<h2 id="overview">📦 Overview</h2>

<p>
This repository provides a <b>headless, lightweight OpenWrt-oriented build</b> of
<a href="https://github.com/telemt/telemt">official telemt</a>, packaged as
<b>IPK</b> and <b>APK</b> for modern OpenWrt targets.
</p>

<p>
The goal is simple: take the upstream Rust daemon, build it in a compact form for
<b>aarch64 musl</b>, and ship it together with an <b>OpenWrt-native init.d + UCI config</b>
layer that actually matches how recent telemt versions behave in production.
</p>

<p>
This is not a fork of the daemon logic. The binary is compiled from the
<b>official upstream source</b>. The main customization is around
<b>packaging, init integration, config generation, reload behavior, and OpenWrt runtime ergonomics</b>.
</p>

<hr/>

<h2 id="whats-included">🧩 What’s included</h2>

<ul>
  <li>✅ <b>Official telemt binary</b> built from <code>telemt/telemt</code></li>
  <li>✅ <b>Optimized aarch64-musl</b> release build for OpenWrt</li>
  <li>✅ <b>UPX-compressed</b> binary to reduce footprint</li>
  <li>✅ <b>OpenWrt init.d service</b> tailored for current telemt runtime behavior</li>
  <li>✅ <b>Default UCI config</b> for OpenWrt integration</li>
  <li>✅ <b>IPK</b> packages for OpenWrt package installation</li>
  <li>✅ <b>APK</b> packages for apk-enabled OpenWrt environments</li>
</ul>

<hr/>

<h2 id="why-this-build-exists">🛠️ Why this build exists</h2>

<p>
Recent telemt releases evolved significantly in runtime structure, API layout, middle-proxy behavior,
hot-reload semantics, and config expectations.
</p>

<p>
Because of that, the old OpenWrt service logic was no longer sufficient. A simple “drop binary into
<code>/usr/bin</code> and keep old init scripts” approach started causing practical issues such as:
</p>

<ul>
  <li>⚠️ stale assumptions in config generation</li>
  <li>⚠️ mismatch between LuCI/UCI state and generated TOML</li>
  <li>⚠️ reload/restart edge cases</li>
  <li>⚠️ non-atomic config replacement races</li>
  <li>⚠️ service stop/restart behavior that was too optimistic for busy routers</li>
  <li>⚠️ compatibility drift with the newer binary’s runtime model</li>
</ul>

<p>
This build addresses that layer specifically.
</p>

<hr/>

<h2 id="openwrt-specific-work">🧠 OpenWrt-specific work</h2>

<p>
The main work in this project is not “changing telemt internals”, but
<b>rewriting the OpenWrt service integration so it matches newer telemt versions</b>.
</p>

<h3>1. Reworked init.d logic</h3>

<p>
The init script was rewritten to better align with current telemt releases:
</p>

<ul>
  <li>✅ cleaner procd integration</li>
  <li>✅ safer service lifecycle handling</li>
  <li>✅ explicit TOML generation path</li>
  <li>✅ OpenWrt-friendly runtime file layout</li>
  <li>✅ correct handling of API / metrics / listener ports</li>
  <li>✅ compatibility with newer telemt config fields and runtime expectations</li>
</ul>

<h3>2. Atomic config updates</h3>

<p>
Special attention was given to config replacement behavior.
On OpenWrt, telemt may watch its runtime TOML, and non-atomic recreation can produce short-lived
missing-file windows. That is unacceptable on a live router.
</p>

<p>
The service logic was adjusted to ensure config writes are performed in an
<b>atomic replace style</b>, minimizing races during reload/restart flows.
</p>

<h3>3. Better reload semantics</h3>

<p>
The newer binary supports hot-reload-related workflows more seriously than older builds,
so the service layer was adapted accordingly.
The goal is to avoid unnecessary full restarts when only dynamic parts change,
while still doing a hard restart when core settings really require it.
</p>

<h3>4. Real-world OpenWrt constraints</h3>

<p>
This package is made for <b>home routers</b>, not generic servers.
That means all decisions are shaped by:
</p>

<ul>
  <li>📉 limited RAM</li>
  <li>📦 limited flash space</li>
  <li>⚙️ BusyBox / ash environments</li>
  <li>🔁 procd service supervision</li>
  <li>🌐 NAT / WAN / port-forward realities</li>
  <li>🧪 practical router admin workflows under root</li>
</ul>

<hr/>

<h2 id="build-pipeline">🏗️ Build pipeline</h2>

<p>
The binary is compiled directly from the official upstream repository:
</p>

<pre><code>telemt/telemt</code></pre>

<p>
The GitHub Actions workflow performs the following steps:
</p>

<ol>
  <li>Fetch target tag or branch</li>
  <li>Checkout this packaging repository</li>
  <li>Checkout upstream <code>telemt/telemt</code> sources</li>
  <li>Install stable Rust toolchain</li>
  <li>Cross-compile for <code>aarch64-unknown-linux-musl</code></li>
  <li>Build with size-oriented release settings</li>
  <li>Compress the resulting binary with <b>UPX</b></li>
  <li>Append a visible version marker to the binary</li>
  <li>Normalize OpenWrt shell scripts with <b>dos2unix</b></li>
  <li>Package final artifacts with <b>nFPM</b> into IPK and APK</li>
  <li>Publish release assets to GitHub Releases</li>
</ol>

<h3>Rust release profile choices</h3>

<p>
The binary is intentionally built in a compact form:
</p>

<ul>
  <li><code>opt-level = z</code> 📉</li>
  <li><code>lto = true</code> 🔗</li>
  <li><code>codegen-units = 1</code> 🧱</li>
  <li><code>panic = abort</code> 💥</li>
  <li><code>strip = true</code> ✂️</li>
</ul>

<p>
This keeps the resulting daemon small and router-friendly while still using the official source tree.
</p>

<hr/>

<h2 id="packages">📁 Packages</h2>

<p>
Build outputs include:
</p>

<ul>
  <li><code>telemt-aarch64-musl</code> — raw standalone binary</li>
  <li><code>telemt_&lt;version&gt;_aarch64_generic.ipk</code></li>
  <li><code>telemt_&lt;version&gt;_aarch64_cortex-a53.ipk</code></li>
  <li><code>telemt_&lt;version&gt;_aarch64_generic.apk</code></li>
  <li><code>telemt_&lt;version&gt;_aarch64_cortex-a53.apk</code></li>
</ul>

<p>
These packages include:
</p>

<ul>
  <li><code>/usr/bin/telemt</code></li>
  <li><code>/etc/init.d/telemt</code></li>
  <li><code>/etc/config/telemt</code></li>
</ul>

<hr/>

<h2 id="installation">📥 Installation</h2>

<h3>IPK</h3>

<pre><code>opkg install ./telemt_&lt;version&gt;_aarch64_generic.ipk</code></pre>

<h3>APK</h3>

<pre><code>apk add --allow-untrusted ./telemt_&lt;version&gt;_aarch64_generic.apk</code></pre>

<h3>Service control</h3>

<pre><code>/etc/init.d/telemt enable
/etc/init.d/telemt start
/etc/init.d/telemt restart
/etc/init.d/telemt stop</code></pre>

<hr/>

<h2 id="notes">📝 Notes</h2>

<ul>
  <li>ℹ️ This repository focuses on the <b>headless daemon package</b></li>
  <li>ℹ️ LuCI integration is handled separately</li>
  <li>ℹ️ The binary itself comes from the <b>official upstream telemt repository</b></li>
  <li>ℹ️ The OpenWrt-specific value here is the <b>service, packaging, and runtime integration layer</b></li>
</ul>

<p>
If you want a WebUI, install the companion LuCI application separately.
</p>

<hr/>

<h2>🎯 Project philosophy</h2>

<p>
Keep the daemon upstream.<br/>
Keep the package lightweight.<br/>
Make the OpenWrt integration correct.
</p>

<p>
That is the whole point of this build.
</p>

<hr/>

<p align="center">
  Made for OpenWrt routers 🧭<br/>
  Built from official telemt sources ⚙️<br/>
  Packaged for practical deployment 📦
</p>
