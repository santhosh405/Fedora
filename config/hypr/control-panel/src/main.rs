mod system;

use gtk4 as gtk;
use gtk::prelude::*;
use gtk::{glib, Application, ApplicationWindow};

const APP_ID: &str = "com.hypr.controlpanel";
const CSS: &str = r#"
window {
    background-color: #0a0a0a;
    color: #e8e8e8;
    font-family: "JetBrains Mono", "Noto Sans", sans-serif;
}

.sidebar {
    background-color: #111111;
}

.nav-btn {
    background-color: transparent;
    color: #b0b0b0;
    border: none;
    border-radius: 0;
    padding: 12px 16px;
    font-size: 13px;
    font-weight: bold;
    border-left: 3px solid transparent;
}

.nav-btn:hover {
    background-color: #1c1c1c;
    color: #ffffff;
}

.nav-btn:checked {
    background-color: #2a0a0a;
    color: #ff4444;
    border-left: 3px solid #ff4444;
}

.content-area {
    background-color: #0a0a0a;
    padding: 24px;
}

.section-title {
    font-size: 18px;
    font-weight: bold;
    color: #ff4444;
    margin-bottom: 8px;
}

.section-desc {
    color: #888888;
    font-size: 12px;
    margin-bottom: 20px;
}

.control-row {
    background-color: #141414;
    border-radius: 8px;
    padding: 12px 16px;
    margin: 4px 0;
}

.control-label {
    font-size: 13px;
    font-weight: bold;
    color: #e8e8e8;
}

.control-value {
    font-size: 12px;
    color: #ff6666;
}

.action-btn {
    background-color: #2a0a0a;
    color: #ff4444;
    border: 1px solid #ff4444;
    border-radius: 6px;
    padding: 6px 14px;
    font-size: 12px;
    font-weight: bold;
}

.action-btn:hover {
    background-color: #ff4444;
    color: #0a0a0a;
}

.toggle {
    min-width: 44px;
    min-height: 22px;
}

.wifi-list {
    background-color: #0d0d0d;
    border: 1px solid #222222;
    border-radius: 6px;
}

.wifi-item {
    background-color: #121212;
    border-radius: 6px;
    padding: 8px 12px;
    margin: 2px 0;
}

.wifi-item:hover {
    background-color: #1e1e1e;
}

.rate-btn {
    background-color: #161616;
    color: #cccccc;
    border: 1px solid #2a2a2a;
    border-radius: 6px;
    padding: 8px 0;
    font-size: 13px;
    font-weight: bold;
}

.rate-btn:hover {
    background-color: #222222;
    color: #ffffff;
}

.rate-btn:checked {
    background-color: #2a0a0a;
    color: #ff4444;
    border-color: #ff4444;
}

separator {
    background-color: #222222;
}

scale trough {
    background-color: #222222;
    border-radius: 4px;
    min-height: 6px;
}

scale highlight {
    background-color: #ff4444;
    border-radius: 4px;
    min-height: 6px;
}

scale slider {
    background-color: #ff4444;
    border-radius: 50%;
    min-width: 16px;
    min-height: 16px;
}

switch {
    background-color: #222222;
    border-radius: 12px;
}

switch:checked {
    background-color: #ff4444;
}

.notification {
    background-color: #1a0a0a;
    color: #ff8888;
    border: 1px solid #ff4444;
    border-radius: 6px;
    padding: 8px 12px;
    font-size: 12px;
}

.bt-item {
    background-color: #121212;
    border-radius: 6px;
    padding: 8px 12px;
    margin: 2px 0;
}

.bt-item:hover {
    background-color: #1e1e1e;
}
"#;

#[derive(Debug, Clone, Copy, PartialEq)]
enum PanelSection {
    Display,
    Network,
    Bluetooth,
    Brightness,
    Audio,
    System,
}

fn main() -> glib::ExitCode {
    let app = Application::builder().application_id(APP_ID).build();

    app.connect_startup(|_| {
        let provider = gtk::CssProvider::new();
        provider.load_from_string(CSS);
        if let Some(screen) = gtk::gdk::Display::default() {
            gtk::style_context_add_provider_for_display(
                &screen,
                &provider,
                gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
            );
        }
    });

    app.connect_activate(|app| {
        build_ui(app);
    });

    app.run()
}

// Small helper to make a row with a label and optional value
fn control_row() -> gtk::Box {
    let row = gtk::Box::new(gtk::Orientation::Horizontal, 12);
    row.add_css_class("control-row");
    row
}

fn section_header(text: &str, desc: &str) -> gtk::Box {
    let boxv = gtk::Box::new(gtk::Orientation::Vertical, 4);
    let title = gtk::Label::new(Some(text));
    title.add_css_class("section-title");
    title.set_halign(gtk::Align::Start);
    let d = gtk::Label::new(Some(desc));
    d.add_css_class("section-desc");
    d.set_halign(gtk::Align::Start);
    boxv.append(&title);
    boxv.append(&d);
    boxv
}

fn build_ui(app: &Application) {
    let window = ApplicationWindow::builder()
        .application(app)
        .title("Control Panel")
        .default_width(900)
        .default_height(600)
        .build();

    let root = gtk::Box::new(gtk::Orientation::Horizontal, 0);
    window.set_child(Some(&root));

    let sidebar = gtk::Box::new(gtk::Orientation::Vertical, 0);
    sidebar.set_width_request(170);
    sidebar.add_css_class("sidebar");
    root.append(&sidebar);

    let header = gtk::Label::new(Some("CONTROLS"));
    header.add_css_class("section-title");
    header.set_halign(gtk::Align::Start);
    header.set_margin_start(16);
    header.set_margin_top(20);
    header.set_margin_bottom(20);
    sidebar.append(&header);

    let content = gtk::Box::new(gtk::Orientation::Vertical, 0);
    content.set_hexpand(true);
    root.append(&content);

    let stack = gtk::Stack::new();
    stack.set_hexpand(true);
    stack.set_vexpand(true);
    content.append(&stack);

    let sections = [
        (PanelSection::Display, "󰹏  Display"),
        (PanelSection::Network, "󰤨  Wi-Fi"),
        (PanelSection::Bluetooth, "󰂯  Bluetooth"),
        (PanelSection::Brightness, "󰃟  Brightness"),
        (PanelSection::Audio, "󰕾  Audio"),
        (PanelSection::System, "󰓅  System"),
    ];

    let mut nav_buttons: Vec<gtk::ToggleButton> = Vec::new();

    for (section, label) in sections.iter() {
        let page = gtk::Box::new(gtk::Orientation::Vertical, 0);
        page.add_css_class("content-area");
        stack.add_named(&page, Some(&format!("{:?}", section)));

        match section {
            PanelSection::Display => build_display_page(&page),
            PanelSection::Network => build_network_page(&page),
            PanelSection::Bluetooth => build_bluetooth_page(&page),
            PanelSection::Brightness => build_brightness_page(&page),
            PanelSection::Audio => build_audio_page(&page),
            PanelSection::System => build_system_page(&page),
        }

        let btn = gtk::ToggleButton::new();
        let lbl = gtk::Label::new(Some(label));
        lbl.set_xalign(0.0);
        btn.set_child(Some(&lbl));
        btn.add_css_class("nav-btn");
        btn.set_halign(gtk::Align::Fill);
        btn.set_hexpand(true);
        if let Some(first) = nav_buttons.first() {
            btn.set_group(Some(first));
        }
        sidebar.append(&btn);

        let sec = *section;
        let stack_clone = stack.clone();
        btn.connect_toggled(move |b| {
            if b.is_active() {
                stack_clone.set_visible_child_name(&format!("{:?}", sec));
            }
        });
        nav_buttons.push(btn.clone());
    }

    if let Some(first) = nav_buttons.first() {
        first.set_active(true);
    }

    let notify = gtk::Label::new(None);
    notify.add_css_class("notification");
    notify.set_halign(gtk::Align::Center);
    notify.set_margin_top(8);
    notify.set_margin_bottom(8);
    notify.set_visible(false);
    content.append(&notify);

    window.present();
}

fn flash(label: &gtk::Label, msg: &str) {
    label.set_text(msg);
    label.set_visible(true);
    let lbl = label.clone();
    glib::timeout_add_seconds_local(3, move || {
        lbl.set_visible(false);
        glib::ControlFlow::Break
    });
}

// ---------------- Display page ----------------

fn build_display_page(page: &gtk::Box) {
    page.append(&section_header(
        "󰹏  Display",
        "Monitor refresh rate control",
    ));

    let notify = gtk::Label::new(None);
    notify.add_css_class("notification");
    notify.set_halign(gtk::Align::Center);
    notify.set_margin_top(4);
    notify.set_margin_bottom(4);
    notify.set_visible(false);

    let monitors = system::get_monitors();
    if monitors.is_empty() {
        let l = gtk::Label::new(Some("No monitors detected"));
        l.add_css_class("control-value");
        page.append(&l);
        return;
    }

    for (name, desc, modes) in &monitors {
        let row = control_row();
        let label_box = gtk::Box::new(gtk::Orientation::Vertical, 2);
        let name_lbl = gtk::Label::new(Some(&format!("󰖴  {} — {}", name, desc)));
        name_lbl.add_css_class("control-label");
        name_lbl.set_halign(gtk::Align::Start);
        label_box.append(&name_lbl);
        row.append(&label_box);

        // Parse current refresh rate
        let current = system::cmd_stdout("hyprctl", &["-j", "monitors"]);
        let mut cur_hz = 0.0;
        if let Ok(json) = serde_json::from_str::<serde_json::Value>(&current) {
            if let Some(arr) = json.as_array() {
                if let Some(m) = arr.iter().find(|m| m["name"].as_str() == Some(name)) {
                    if let Some(f) = m["refreshRate"].as_f64() {
                        cur_hz = f;
                    }
                }
            }
        }

        let val_lbl = gtk::Label::new(Some(&format!("Current: {:.0} Hz", cur_hz)));
        val_lbl.add_css_class("control-value");
        val_lbl.set_halign(gtk::Align::Start);
        label_box.append(&val_lbl);

        // Refresh rate buttons
        let mut uniq: Vec<String> = Vec::new();
        for m in modes {
            let hz = m.trim_end_matches("Hz").to_string();
            if !uniq.contains(&hz) {
                uniq.push(hz);
            }
        }
        if uniq.is_empty() {
            uniq = vec!["144".to_string(), "120".to_string(), "60".to_string()];
        }

        let grid = gtk::Grid::new();
        grid.set_column_spacing(8);
        grid.set_row_spacing(8);
        grid.set_halign(gtk::Align::Start);
        grid.set_margin_top(8);

        let mon = name.clone();
        let notify_clone = notify.clone();
        for (i, hz) in uniq.iter().enumerate() {
            let btn = gtk::ToggleButton::with_label(hz);
            btn.add_css_class("rate-btn");
            let h = hz.clone();
            let m2 = mon.clone();
            let nf = notify_clone.clone();
            btn.connect_toggled(move |b| {
                if b.is_active() {
                    system::set_refresh_rate(&m2, &format!("{}.00Hz", h));
                    flash(&nf, &format!("Set {} to {} Hz", m2, h));
                }
            });
            grid.attach(&btn, i as i32 % 4, i as i32 / 4, 1, 1);
        }

        page.append(&row);
        page.append(&grid);
    }

    page.append(&notify);
}

// ---------------- Network page ----------------

fn build_network_page(page: &gtk::Box) {
    page.append(&section_header(
        "󰤨  Wi-Fi",
        "Connect to available networks",
    ));

    let notify = gtk::Label::new(None);
    notify.add_css_class("notification");
    notify.set_halign(gtk::Align::Center);
    notify.set_margin_top(4);
    notify.set_margin_bottom(4);
    notify.set_visible(false);
    page.append(&notify);

    // Status row
    let row = control_row();
    let label_box = gtk::Box::new(gtk::Orientation::Vertical, 2);
    let name_lbl = gtk::Label::new(Some("Wi-Fi Status"));
    name_lbl.add_css_class("control-label");
    name_lbl.set_halign(gtk::Align::Start);
    label_box.append(&name_lbl);
    let status_lbl = gtk::Label::new(None);
    status_lbl.add_css_class("control-value");
    status_lbl.set_halign(gtk::Align::Start);
    label_box.append(&status_lbl);
    row.append(&label_box);
    row.set_hexpand(true);

    let cur = system::wifi_current();
    if cur.is_empty() {
        status_lbl.set_text("Not connected");
    } else {
        status_lbl.set_text(&format!("Connected to: {}", cur));
    }

    let sw = gtk::Switch::new();
    sw.add_css_class("toggle");
    sw.set_halign(gtk::Align::End);
    sw.set_valign(gtk::Align::Center);
    sw.set_active(system::wifi_enabled());
    row.append(&sw);

    let nf = notify.clone();
    sw.connect_state_set(move |_, on| {
        system::wifi_toggle(on);
        flash(&nf, if on { "Wi-Fi enabled" } else { "Wi-Fi disabled" });
        glib::Propagation::Proceed
    });

    page.append(&row);

    // Refresh button
    let refresh_row = control_row();
    let rlbl = gtk::Label::new(Some("Available Networks"));
    rlbl.add_css_class("control-label");
    rlbl.set_halign(gtk::Align::Start);
    refresh_row.set_hexpand(true);
    refresh_row.append(&rlbl);

    let scan_btn = gtk::Button::with_label("󰐗  Scan");
    scan_btn.add_css_class("action-btn");
    let list_box = gtk::Box::new(gtk::Orientation::Vertical, 4);
    list_box.add_css_class("wifi-list");

    let list_clone = list_box.clone();
    let nf2 = notify.clone();
    scan_btn.connect_clicked(move |_| {
        refresh_wifi_list(&list_clone);
        flash(&nf2, "Scanning networks...");
    });
    refresh_row.append(&scan_btn);
    page.append(&refresh_row);

    page.append(&list_box);
    refresh_wifi_list(&list_box);
}

fn refresh_wifi_list(list_box: &gtk::Box) {
    while let Some(child) = list_box.first_child() {
        list_box.remove(&child);
    }

    let nets = system::wifi_scan();
    if nets.is_empty() {
        let l = gtk::Label::new(Some("  No networks found"));
        l.add_css_class("control-value");
        l.set_halign(gtk::Align::Start);
        list_box.append(&l);
        return;
    }

    for (ssid, signal, security, in_use) in nets {
        let item = gtk::Box::new(gtk::Orientation::Horizontal, 8);
        item.add_css_class("wifi-item");
        item.set_hexpand(true);

        let bars = signal.parse::<u32>().unwrap_or(0);
        let sig_icon = if bars >= 75 {
            "󰤨"
        } else if bars >= 50 {
            "󰤥"
        } else if bars >= 25 {
            "󰤢"
        } else {
            "󰤟"
        };

        let ssid_lbl = gtk::Label::new(Some(&format!("{}  {}  ({})", sig_icon, ssid, signal)));
        ssid_lbl.add_css_class("control-label");
        ssid_lbl.set_halign(gtk::Align::Start);
        ssid_lbl.set_hexpand(true);
        item.append(&ssid_lbl);

        if security.is_empty() || security == "--" {
            let sec_lbl = gtk::Label::new(Some("open"));
            sec_lbl.add_css_class("control-value");
            item.append(&sec_lbl);
        } else if in_use {
            let cur_lbl = gtk::Label::new(Some("connected"));
            cur_lbl.add_css_class("control-value");
            item.append(&cur_lbl);
        }

        if !in_use {
            let connect_btn = gtk::Button::with_label("Connect");
            connect_btn.add_css_class("action-btn");
            let s = ssid.clone();
            connect_btn.connect_clicked(move |_| {
                system::wifi_connect(&s, None);
                // If it needs a password it will fail silently; try again with prompt in terminal app? Keep simple.
            });
            item.append(&connect_btn);
        } else {
            let dis_btn = gtk::Button::with_label("Disconnect");
            dis_btn.add_css_class("action-btn");
            dis_btn.connect_clicked(|_| {
                system::wifi_disconnect();
            });
            item.append(&dis_btn);
        }

        list_box.append(&item);
    }
}

// ---------------- Bluetooth page ----------------

fn build_bluetooth_page(page: &gtk::Box) {
    page.append(&section_header(
        "󰂯  Bluetooth",
        "Manage Bluetooth devices",
    ));

    let notify = gtk::Label::new(None);
    notify.add_css_class("notification");
    notify.set_halign(gtk::Align::Center);
    notify.set_margin_top(4);
    notify.set_margin_bottom(4);
    notify.set_visible(false);
    page.append(&notify);

    let row = control_row();
    let label_box = gtk::Box::new(gtk::Orientation::Vertical, 2);
    let name_lbl = gtk::Label::new(Some("Bluetooth Status"));
    name_lbl.add_css_class("control-label");
    name_lbl.set_halign(gtk::Align::Start);
    label_box.append(&name_lbl);
    let status_lbl = gtk::Label::new(None);
    status_lbl.add_css_class("control-value");
    status_lbl.set_halign(gtk::Align::Start);
    label_box.append(&status_lbl);
    row.append(&label_box);
    row.set_hexpand(true);

    let sw = gtk::Switch::new();
    sw.add_css_class("toggle");
    sw.set_halign(gtk::Align::End);
    sw.set_valign(gtk::Align::Center);
    sw.set_active(system::bt_enabled());
    row.append(&sw);

    let nf = notify.clone();
    sw.connect_state_set(move |_, on| {
        system::bt_toggle(on);
        flash(&nf, if on { "Bluetooth enabled" } else { "Bluetooth disabled" });
        glib::Propagation::Proceed
    });

    page.append(&row);

    // Scan button + device list
    let refresh_row = control_row();
    let rlbl = gtk::Label::new(Some("Paired Devices"));
    rlbl.add_css_class("control-label");
    rlbl.set_halign(gtk::Align::Start);
    refresh_row.set_hexpand(true);
    refresh_row.append(&rlbl);

    let scan_btn = gtk::Button::with_label("󰐗  Scan");
    scan_btn.add_css_class("action-btn");
    let list_box = gtk::Box::new(gtk::Orientation::Vertical, 4);
    list_box.add_css_class("wifi-list");

    let list_clone = list_box.clone();
    let nf2 = notify.clone();
    scan_btn.connect_clicked(move |_| {
        system::bt_scan();
        refresh_bt_list(&list_clone);
        flash(&nf2, "Bluetooth scan complete");
    });
    refresh_row.append(&scan_btn);
    page.append(&refresh_row);

    page.append(&list_box);
    refresh_bt_list(&list_box);
}

fn refresh_bt_list(list_box: &gtk::Box) {
    while let Some(child) = list_box.first_child() {
        list_box.remove(&child);
    }

    let devs = system::bt_paired();
    if devs.is_empty() {
        let l = gtk::Label::new(Some("  No paired devices"));
        l.add_css_class("control-value");
        l.set_halign(gtk::Align::Start);
        list_box.append(&l);
        return;
    }

    for (addr, name) in devs {
        let item = gtk::Box::new(gtk::Orientation::Horizontal, 8);
        item.add_css_class("bt-item");
        item.set_hexpand(true);

        let name_lbl = gtk::Label::new(Some(&format!("󰂯  {}  ({})", name, addr)));
        name_lbl.add_css_class("control-label");
        name_lbl.set_halign(gtk::Align::Start);
        name_lbl.set_hexpand(true);
        item.append(&name_lbl);

        let connect_btn = gtk::Button::new();
        connect_btn.add_css_class("action-btn");
        if system::bt_is_connected(&addr) {
            connect_btn.set_label("Disconnect");
        } else {
            connect_btn.set_label("Connect");
        }
        let a = addr.clone();
        connect_btn.connect_clicked(move |b| {
            if b.label() == Some("Disconnect".into()) {
                system::bt_disconnect(&a);
                b.set_label("Connect");
            } else {
                system::bt_connect(&a);
                b.set_label("Disconnect");
            }
        });
        item.append(&connect_btn);

        list_box.append(&item);
    }
}

// ---------------- Brightness page ----------------

fn build_brightness_page(page: &gtk::Box) {
    page.append(&section_header(
        "󰃟  Brightness",
        "Adjust screen brightness",
    ));

    let notify = gtk::Label::new(None);
    notify.add_css_class("notification");
    notify.set_halign(gtk::Align::Center);
    notify.set_margin_top(4);
    notify.set_margin_bottom(4);
    notify.set_visible(false);
    page.append(&notify);

    let (cur, max) = system::brightness_get();
    let pct = if max > 0 { cur * 100 / max } else { 50 };

    let row = control_row();
    let label_box = gtk::Box::new(gtk::Orientation::Vertical, 2);
    let name_lbl = gtk::Label::new(Some("Screen Brightness"));
    name_lbl.add_css_class("control-label");
    name_lbl.set_halign(gtk::Align::Start);
    label_box.append(&name_lbl);
    let val_lbl = gtk::Label::new(Some(&format!("{}%", pct)));
    val_lbl.add_css_class("control-value");
    val_lbl.set_halign(gtk::Align::Start);
    label_box.append(&val_lbl);
    row.append(&label_box);
    row.set_hexpand(true);

    let adj = gtk::Adjustment::new(pct as f64, 0.0, 100.0, 1.0, 5.0, 0.0);
    let scale = gtk::Scale::new(gtk::Orientation::Horizontal, Some(&adj));
    scale.set_hexpand(true);
    scale.set_width_request(250);
    row.append(&scale);

    let vl = val_lbl.clone();
    let nf = notify.clone();
    adj.connect_value_changed(move |a| {
        let v = a.value() as u32;
        system::brightness_set(v);
        vl.set_text(&format!("{}%", v));
        flash(&nf, &format!("Brightness: {}%", v));
    });

    page.append(&row);
}

// ---------------- Audio page ----------------

fn build_audio_page(page: &gtk::Box) {
    page.append(&section_header(
        "󰕾  Audio",
        "System volume control",
    ));

    let notify = gtk::Label::new(None);
    notify.add_css_class("notification");
    notify.set_halign(gtk::Align::Center);
    notify.set_margin_top(4);
    notify.set_margin_bottom(4);
    notify.set_visible(false);
    page.append(&notify);

    let vol = system::volume_get();

    let row = control_row();
    let label_box = gtk::Box::new(gtk::Orientation::Vertical, 2);
    let name_lbl = gtk::Label::new(Some("Volume"));
    name_lbl.add_css_class("control-label");
    name_lbl.set_halign(gtk::Align::Start);
    label_box.append(&name_lbl);
    let val_lbl = gtk::Label::new(Some(&format!("{}%", vol)));
    val_lbl.add_css_class("control-value");
    val_lbl.set_halign(gtk::Align::Start);
    label_box.append(&val_lbl);
    row.append(&label_box);
    row.set_hexpand(true);

    let adj = gtk::Adjustment::new(vol as f64, 0.0, 150.0, 1.0, 5.0, 0.0);
    let scale = gtk::Scale::new(gtk::Orientation::Horizontal, Some(&adj));
    scale.set_hexpand(true);
    scale.set_width_request(250);
    row.append(&scale);

    let vl = val_lbl.clone();
    adj.connect_value_changed(move |a| {
        let v = a.value() as u32;
        system::volume_set(v);
        vl.set_text(&format!("{}%", v));
    });

    page.append(&row);

    let mute_row = control_row();
    let mute_lbl = gtk::Label::new(Some("Mute"));
    mute_lbl.add_css_class("control-label");
    mute_lbl.set_halign(gtk::Align::Start);
    mute_lbl.set_hexpand(true);
    mute_row.append(&mute_lbl);
    let mute_sw = gtk::Switch::new();
    mute_sw.add_css_class("toggle");
    mute_sw.set_active(system::audio_sink_mute());
    let nf = notify.clone();
    mute_sw.connect_state_set(move |_, on| {
        system::volume_mute(on);
        flash(&nf, if on { "Muted" } else { "Unmuted" });
        glib::Propagation::Proceed
    });
    mute_row.append(&mute_sw);
    page.append(&mute_row);
}

// ---------------- System page ----------------

fn build_system_page(page: &gtk::Box) {
    page.append(&section_header(
        "󰓅  System",
        "System information & power control",
    ));

    // Info row
    let (bat_pct, charging) = system::battery_info();
    let cpu = system::cpu_usage();
    let mem = system::memory_usage();

    let row = control_row();
    let label_box = gtk::Box::new(gtk::Orientation::Vertical, 2);
    let name_lbl = gtk::Label::new(Some("System Status"));
    name_lbl.add_css_class("control-label");
    name_lbl.set_halign(gtk::Align::Start);
    label_box.append(&name_lbl);
    let status = format!(
        "CPU: {}%   RAM: {}%   Battery: {}% ({})",
        cpu,
        mem,
        bat_pct,
        if charging { "charging" } else { "discharging" }
    );
    let val_lbl = gtk::Label::new(Some(&status));
    val_lbl.add_css_class("control-value");
    val_lbl.set_halign(gtk::Align::Start);
    label_box.append(&val_lbl);
    row.append(&label_box);
    row.set_hexpand(true);
    page.append(&row);

    // Power actions
    let action_row = control_row();
    let a_lbl = gtk::Label::new(Some("Power"));
    a_lbl.add_css_class("control-label");
    a_lbl.set_halign(gtk::Align::Start);
    action_row.append(&a_lbl);

    let lock_btn = gtk::Button::with_label("󰌾 Lock");
    lock_btn.add_css_class("action-btn");
    lock_btn.connect_clicked(|_| {
        system::lock();
    });
    action_row.append(&lock_btn);

    let suspend_btn = gtk::Button::with_label("󰤄 Suspend");
    suspend_btn.add_css_class("action-btn");
    suspend_btn.connect_clicked(|_| {
        system::suspend();
    });
    action_row.append(&suspend_btn);

    let reboot_btn = gtk::Button::with_label("󰜉 Reboot");
    reboot_btn.add_css_class("action-btn");
    reboot_btn.connect_clicked(|_| {
        system::reboot();
    });
    action_row.append(&reboot_btn);

    let shutdown_btn = gtk::Button::with_label("󰤂 Shutdown");
    shutdown_btn.add_css_class("action-btn");
    shutdown_btn.connect_clicked(|_| {
        system::shutdown();
    });
    action_row.append(&shutdown_btn);

    page.append(&action_row);
}
