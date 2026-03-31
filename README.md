<h1 align="center">🚀 Headless Telemt для OpenWrt</h1>

<p align="center">
  Легковесные пакеты бинарников <b>Telegram MTProxy</b> для OpenWrt 21-25<br/>
  <i>Собрано из официального репозитория <code>telemt/telemt</code> и адаптировано для реального использования на OpenWrt</i>
</p>

<p align="center">
  <a href="#overview">Обзор</a> •
  <a href="#whats-included">Что внутри</a> •
  <a href="#why-this-build-exists">Зачем нужна эта сборка</a> •
  <a href="#build-pipeline">Процесс сборки</a> •
  <a href="#openwrt-specific-work">Специфика OpenWrt</a> •
  <a href="#packages">Пакеты</a> •
  <a href="#installation">Установка</a> •
  <a href="#notes">Примечания</a>
</p>

<hr/>

<h2 id="overview">📦 Обзор</h2>

<p>
Этот репозиторий предоставляет <b>легковесную сборку без графического интерфейса (headless), ориентированную на OpenWrt</b>, на базе <a href="https://github.com/telemt/telemt">официального telemt</a>, упакованную в форматы <b>IPK</b> и <b>APK</b> для современных платформ OpenWrt.
</p>

<p>
Цель проста: взять официальный Rust-демон (апстрим), скомпилировать его в компактном виде под <b>aarch64 musl</b> и поставлять вместе с <b>нативным слоем OpenWrt (init.d + конфигурация UCI)</b>, который реально соответствует поведению последних версий telemt в продакшене.
</p>

<p>
Это не форк логики самого демона. Бинарник компилируется из <b>официального исходного кода</b>. Основные доработки касаются <b>упаковки, интеграции с init, генерации конфигурации, логики перезагрузки (reload) и эргономики работы в среде OpenWrt</b>.
</p>

<hr/>

<h2 id="whats-included">🧩 Что внутри</h2>

<ul>
  <li>✅ <b>Официальный бинарник telemt</b>, собранный из <code>telemt/telemt</code></li>
  <li>✅ <b>Оптимизированная aarch64-musl</b> релизная сборка для OpenWrt</li>
  <li>✅ <b>Сжатый через UPX</b> бинарник для уменьшения размера</li>
  <li>✅ <b>Сервис OpenWrt init.d</b>, адаптированный под текущее поведение демона telemt</li>
  <li>✅ <b>Конфигурация UCI по умолчанию</b> для интеграции с OpenWrt</li>
  <li>✅ Пакеты <b>IPK</b> для стандартной установки в OpenWrt</li>
  <li>✅ Пакеты <b>APK</b> для сред OpenWrt с поддержкой пакетного менеджера apk</li>
</ul>

<hr/>

<h2 id="why-this-build-exists">🛠️ Зачем нужна эта сборка</h2>

<p>
Последние релизы telemt претерпели значительные изменения в структуре рантайма, расположении API, поведении middle-прокси, семантике горячей перезагрузки (hot-reload) и требованиях к конфигурации.
</p>

<p>
Из-за этого старая логика сервисов OpenWrt перестала справляться. Простой подход «закинуть бинарник в <code>/usr/bin</code> и оставить старые init-скрипты» начал вызывать практические проблемы, такие как:
</p>

<ul>
  <li>⚠️ устаревшие подходы при генерации конфигов</li>
  <li>⚠️ рассинхрон между состоянием LuCI/UCI и сгенерированным TOML</li>
  <li>⚠️ пограничные случаи при перезапуске/перезагрузке (reload/restart)</li>
  <li>⚠️ состояние гонки (race conditions) при неатомарной замене конфигов</li>
  <li>⚠️ поведение при остановке/перезапуске сервиса, которое было слишком «оптимистичным» для загруженных роутеров</li>
  <li>⚠️ потеря совместимости с рантайм-моделью нового бинарника</li>
</ul>

<p>
Данная сборка решает проблемы именно на этом уровне.
</p>

<hr/>

<h2 id="openwrt-specific-work">🧠 Специфика OpenWrt</h2>

<p>
Главная работа в этом проекте заключается не в «изменении внутренностей telemt», а в <b>переписывании интеграции сервиса под OpenWrt, чтобы она соответствовала новым версиям telemt</b>.
</p>

<h3>1. Переработанная логика init.d</h3>

<p>
Скрипт инициализации был переписан для лучшей совместимости с актуальными релизами telemt:
</p>

<ul>
  <li>✅ более чистая интеграция с procd</li>
  <li>✅ более безопасное управление жизненным циклом сервиса</li>
  <li>✅ явный путь генерации TOML</li>
  <li>✅ удобное для OpenWrt расположение файлов времени выполнения</li>
  <li>✅ корректная обработка портов API / метрик / листенеров</li>
  <li>✅ совместимость с новыми полями конфигурации telemt и требованиями рантайма</li>
</ul>

<h3>2. Атомарное обновление конфигурации</h3>

<p>
Особое внимание было уделено поведению при замене конфигурации.
В OpenWrt telemt может отслеживать свой рабочий TOML-файл, и неатомарное пересоздание файла может привести к кратковременным окнам, когда файл отсутствует. Это недопустимо на работающем роутере.
</p>

<p>
Логика сервиса была скорректирована таким образом, чтобы запись конфигурации выполнялась в стиле <b>атомарной замены</b>, минимизируя состояние гонки во время процессов reload/restart.
</p>

<h3>3. Улучшенная логика reload (перезагрузки)</h3>

<p>
Новый бинарник более серьезно поддерживает рабочие процессы, связанные с горячей перезагрузкой (hot-reload), поэтому слой сервиса был соответствующе адаптирован.
Цель — избежать ненужных полных перезапусков (hard restart), когда меняются только динамические параметры, при этом сохраняя жесткий перезапуск, когда этого действительно требуют базовые настройки.
</p>

<h3>4. Реальные ограничения OpenWrt</h3>

<p>
Этот пакет создан для <b>домашних роутеров</b>, а не для обычных серверов.
Это означает, что все решения принимаются с учетом:
</p>

<ul>
  <li>📉 ограниченного объема ОЗУ (RAM)</li>
  <li>📦 ограниченного места на флеш-памяти</li>
  <li>⚙️ окружения BusyBox / ash</li>
  <li>🔁 управления сервисами через procd</li>
  <li>🌐 реалий NAT / WAN / проброса портов</li>
  <li>🧪 практических рабочих процессов администрирования роутера под root</li>
</ul>

<hr/>

<h2 id="build-pipeline">🏗️ Процесс сборки</h2>

<p>
Бинарник компилируется напрямую из официального upstream-репозитория:
</p>

<pre><code>telemt/telemt</code></pre>

<p>
Пайплайн GitHub Actions выполняет следующие шаги:
</p>

<ol>
  <li>Получение целевого тега или ветки</li>
  <li>Чекаут этого репозитория с пакетами</li>
  <li>Чекаут исходников апстрима <code>telemt/telemt</code></li>
  <li>Установка стабильного тулчейна Rust</li>
  <li>Кросс-компиляция под <code>aarch64-unknown-linux-musl</code></li>
  <li>Сборка с настройками релиза, ориентированными на минимальный размер</li>
  <li>Сжатие итогового бинарника с помощью <b>UPX</b></li>
  <li>Добавление видимого маркера версии в бинарник</li>
  <li>Нормализация shell-скриптов OpenWrt с помощью <b>dos2unix</b></li>
  <li>Упаковка финальных артефактов через <b>nFPM</b> в IPK и APK</li>
  <li>Публикация релизных ассетов в GitHub Releases</li>
</ol>

<h3>Параметры релизного профиля Rust</h3>

<p>
Бинарник намеренно собирается в компактном виде:
</p>

<ul>
  <li><code>opt-level = z</code> 📉</li>
  <li><code>lto = true</code> 🔗</li>
  <li><code>codegen-units = 1</code> 🧱</li>
  <li><code>panic = abort</code> 💥</li>
  <li><code>strip = true</code> ✂️</li>
</ul>

<p>
Это позволяет сделать демон компактным и удобным для роутеров, при этом используя официальное дерево исходников.
</p>

<hr/>

<h2 id="packages">📁 Пакеты</h2>

<p>
Результаты сборки включают:
</p>

<ul>
  <li><code>telemt-aarch64-musl</code> — сырой автономный бинарник</li>
  <li><code>telemt_&lt;version&gt;_aarch64_generic.ipk</code></li>
  <li><code>telemt_&lt;version&gt;_aarch64_cortex-a53.ipk</code></li>
  <li><code>telemt_&lt;version&gt;_aarch64_generic.apk</code></li>
  <li><code>telemt_&lt;version&gt;_aarch64_cortex-a53.apk</code></li>
</ul>

<p>
Эти пакеты содержат:
</p>

<ul>
  <li><code>/usr/bin/telemt</code></li>
  <li><code>/etc/init.d/telemt</code></li>
  <li><code>/etc/config/telemt</code></li>
</ul>

<hr/>

<h2 id="installation">📥 Установка</h2>

<h3>IPK</h3>

<pre><code>opkg install ./telemt_&lt;version&gt;_aarch64_generic.ipk</code></pre>

<h3>APK</h3>

<pre><code>apk add --allow-untrusted ./telemt_&lt;version&gt;_aarch64_generic.apk</code></pre>

<h3>Управление сервисом</h3>

<pre><code>/etc/init.d/telemt enable
/etc/init.d/telemt start
/etc/init.d/telemt restart
/etc/init.d/telemt stop</code></pre>

<hr/>

<h2 id="notes">📝 Примечания</h2>

<ul>
  <li>ℹ️ Этот репозиторий сфокусирован на <b>Headless-пакете демона</b> (без GUI)</li>
  <li>ℹ️ Интеграция с LuCI поставляется отдельно</li>
  <li>ℹ️ Сам бинарник берется из <b>официального upstream-репозитория telemt</b></li>
  <li>ℹ️ Основная ценность сборки для OpenWrt заключается в <b>интеграции сервиса, упаковке и среде выполнения</b></li>
</ul>

<p>
Если вам нужен веб-интерфейс, установите сопутствующее приложение LuCI отдельно.
</p>

<hr/>

<h2>🎯 Философия проекта</h2>

<p>
Оставлять демона в апстриме.<br/>
Делать пакет легковесным.<br/>
Обеспечивать правильную интеграцию с OpenWrt.
</p>

<p>
В этом и заключается весь смысл данной сборки.
</p>

<hr/>

<p align="center">
  Сделано для роутеров OpenWrt 🧭<br/>
  Собрано из официальных исходников telemt ⚙️<br/>
  Упаковано для практического применения 📦
</p>

<br/>

---

### 📋 English Summary
**Headless Telemt for OpenWrt** is a highly optimized, headless packaging of the official Telegram MTProxy daemon (`telemt`) designed specifically for OpenWrt routers. Rather than forking the core binary, this project compiles the upstream Rust code for `aarch64-musl` with aggressive size optimizations (UPX, `opt-level=z`, `lto=true`) and pairs it with a completely rewritten `init.d` and UCI configuration layer. This custom integration solves real-world router issues like atomic config generation, safe hot-reloading, `procd` supervision, and memory constraints. The output includes ready-to-install IPK and APK packages. (Note: The LuCI WebUI is not included and must be installed as a separate module).
