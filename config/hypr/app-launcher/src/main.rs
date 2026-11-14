use gtk4 as gtk;
use gtk::prelude::*;
use gtk::{glib, Application, ApplicationWindow};
use std::cell::RefCell;
use std::process::Command;
use std::rc::Rc;

const CONFIG_PATH: &str = "/home/fuckwindows/.config/hypr/app-launcher/config.lua";

const CSS: &str = r#"
window {
    background-color: #0a0a0a;
    color: #e8e8e8;
    font-family: "JetBrains Mono", "Noto Sans", sans-serif;
}
.launcher-root {
    padding: 18px;
}
.searchbar {
    background-color: #161616;
    color: #e8e8e8;
    border-radius: 10px;
    border: 1px solid #2c2c2c;
    padding: 6px 12px;
    font-size: 14px;
}
.searchbar:focus {
    border-color: #ff4444;
}
.searchbar selection {
    background-color: #ff4444;
    color: #0a0a0a;
}
.tile-grid {
    margin-top: 8px;
}
.tile {
    background-color: #141414;
    border-radius: 14px;
    border: 1px solid #262626;
    padding: 14px 10px;
}
.tile:hover {
    background-color: #1e0d0d;
    border-color: #7a1c1c;
}
.tile.selected {
    background-color: #2a0a0a;
    border: 2px solid #ff4444;
}
.tile-btn {
    background: transparent;
    border: none;
    box-shadow: none;
}
.tile-name {
    color: #f0f0f0;
    font-size: 12px;
    font-weight: 700;
}
.tile-comment {
    color: #7a7a7a;
    font-size: 10px;
}
"#;

#[derive(Clone)]
struct AppEntry {
    name: String,
    icon: String,
    exec: String,
    comment: String,
}

struct SelState {
    children: Vec<gtk::FlowBoxChild>,
    entries: Vec<AppEntry>,
    visible: Vec<usize>,
    selected: usize,
}

fn default_entries() -> Vec<AppEntry> {
    vec![
        AppEntry {
            name: "Kiro".into(),
            icon: "utilities-terminal".into(),
            exec: "\"/home/fuckwindows/Downloads/kiro-ide-1.0.116-stable-linux-x64/Kiro/kiro\"".into(),
            comment: "IDE".into(),
        },
        AppEntry {
            name: "Brave".into(),
            icon: "brave-browser".into(),
            exec: "brave-browser".into(),
            comment: "Web Browser".into(),
        },
        AppEntry {
            name: "Control Panel".into(),
            icon: "preferences-system".into(),
            exec: "/home/fuckwindows/.config/hypr/control-panel/target/release/hypr-control-panel".into(),
            comment: "System Settings".into(),
        },
        AppEntry {
            name: "MSI Control Center".into(),
            icon: "utilities-system-monitor".into(),
            exec: "python3 /home/fuckwindows/.config/hypr/msi-control-center/main.py".into(),
            comment: "Fan & Power".into(),
        },
        AppEntry {
            name: "Env Vault".into(),
            icon: "dialog-password".into(),
            exec: "kitty /home/fuckwindows/.config/hypr/envvault/target/release/envvault unlock".into(),
            comment: "Encrypted .env credentials".into(),
        },
    ]
}

fn load_config() -> Vec<AppEntry> {
    let src = match std::fs::read_to_string(CONFIG_PATH) {
        Ok(s) => s,
        Err(e) => {
            eprintln!("[app-launcher] cannot read {}: {}", CONFIG_PATH, e);
            return default_entries();
        }
    };
    let lua = mlua::Lua::new();
    if let Err(e) = lua.load(&src).exec() {
        eprintln!("[app-launcher] lua error: {}", e);
        return default_entries();
    }
    let table: mlua::Table = match lua.globals().get("apps") {
        Ok(t) => t,
        Err(e) => {
            eprintln!("[app-launcher] lua error: {}", e);
            return default_entries();
        }
    };
    let mut out = Vec::new();
    for pair in table.sequence_values::<mlua::Table>() {
        let Ok(t) = pair else { continue };
        out.push(AppEntry {
            name: t.get("name").unwrap_or_default(),
            icon: t.get("icon").unwrap_or_default(),
            exec: t.get("exec").unwrap_or_default(),
            comment: t.get("comment").unwrap_or_default(),
        });
    }
    if out.is_empty() {
        eprintln!("[app-launcher] empty app list, using defaults");
        default_entries()
    } else {
        out
    }
}

fn make_image(icon: &str) -> gtk::Image {
    let img = if icon.starts_with('/') {
        gtk::Image::from_file(icon)
    } else {
        let theme = gtk::IconTheme::new();
        let name = if theme.has_icon(icon) {
            icon
        } else {
            "applications-development"
        };
        gtk::Image::from_icon_name(name)
    };
    img.set_pixel_size(48);
    img
}

fn build_tile(e: &AppEntry) -> gtk::Button {
    let btn = gtk::Button::new();
    btn.add_css_class("tile-btn");

    let v = gtk::Box::new(gtk::Orientation::Vertical, 6);
    v.set_halign(gtk::Align::Center);
    v.set_valign(gtk::Align::Center);

    let img = make_image(&e.icon);
    img.set_pixel_size(48);
    v.append(&img);

    let name = gtk::Label::new(Some(&e.name));
    name.add_css_class("tile-name");
    v.append(&name);

    if !e.comment.is_empty() {
        let c = gtk::Label::new(Some(&e.comment));
        c.add_css_class("tile-comment");
        v.append(&c);
    }

    btn.set_child(Some(&v));
    btn
}

fn launch(exec: &str) {
    let cmd = format!("{} &", exec);
    let _ = Command::new("sh").arg("-c").arg(cmd).spawn();
}

fn apply_selection(state: &mut SelState) {
    let sel_idx = state.visible.get(state.selected).copied();
    for (i, child) in state.children.iter().enumerate() {
        if sel_idx == Some(i) {
            child.add_css_class("selected");
        } else {
            child.remove_css_class("selected");
        }
    }
    if let Some(idx) = sel_idx {
        let _ = state.children.get(idx);
    }
}

fn filter(state: &mut SelState, query: &str) {
    state.visible.clear();
    let q = query.to_lowercase();
    for (i, e) in state.entries.iter().enumerate() {
        let hay = format!("{} {} {}", e.name, e.comment, e.exec).to_lowercase();
        if hay.contains(&q) {
            state.visible.push(i);
        }
    }
    state.selected = 0;
    apply_selection(state);
}

fn build_ui(app: &Application) {
    let window = ApplicationWindow::builder()
        .application(app)
        .title("App Launcher")
        .default_width(780)
        .default_height(500)
        .build();
    window.set_decorated(false);
    window.set_resizable(false);

    let provider = gtk::CssProvider::new();
    provider.load_from_string(CSS);
    if let Some(disp) = gtk::gdk::Display::default() {
        gtk::style_context_add_provider_for_display(
            &disp,
            &provider,
            gtk::STYLE_PROVIDER_PRIORITY_APPLICATION,
        );
    }

    let root = gtk::Box::new(gtk::Orientation::Vertical, 12);
    root.add_css_class("launcher-root");
    window.set_child(Some(&root));

    let search = gtk::SearchEntry::new();
    search.add_css_class("searchbar");
    search.set_placeholder_text(Some("Search apps..."));
    search.set_hexpand(true);
    root.append(&search);

    let flow = gtk::FlowBox::new();
    flow.set_max_children_per_line(6);
    flow.set_min_children_per_line(1);
    flow.set_column_spacing(10);
    flow.set_row_spacing(10);
    flow.set_selection_mode(gtk::SelectionMode::None);
    flow.set_activate_on_single_click(false);
    flow.set_vexpand(true);
    flow.set_hexpand(true);
    flow.add_css_class("tile-grid");
    root.append(&flow);

    let entries_vec = load_config();

    let mut children = Vec::new();
    let mut entries = Vec::new();
    for e in &entries_vec {
        let tile = build_tile(e);
        let child = gtk::FlowBoxChild::new();
        child.add_css_class("tile");
        child.set_child(Some(&tile));

        let exec = e.exec.clone();
        let win = window.clone();
        tile.connect_clicked(move |_| {
            launch(&exec);
            win.close();
        });

        flow.append(&child);
        children.push(child);
        entries.push(e.clone());
    }

    let state = Rc::new(RefCell::new(SelState {
        children,
        entries,
        visible: (0..entries_vec.len()).collect(),
        selected: 0,
    }));

    apply_selection(&mut state.borrow_mut());

    let state_c = state.clone();
    let flow_c = flow.clone();
    search.connect_search_changed(move |s| {
        let mut st = state_c.borrow_mut();
        let _ = &flow_c;
        filter(&mut st, &s.text().to_string());
    });

    let ctrl = gtk::EventControllerKey::new();
    let state_c = state.clone();
    ctrl.connect_key_pressed(move |_, key, _, _| {
        let mut st = state_c.borrow_mut();
        match key {
            gtk::gdk::Key::Down | gtk::gdk::Key::Right => {
                if !st.visible.is_empty() {
                    st.selected = (st.selected + 1).min(st.visible.len() - 1);
                    apply_selection(&mut st);
                }
                glib::Propagation::Stop
            }
            gtk::gdk::Key::Up | gtk::gdk::Key::Left => {
                if !st.visible.is_empty() {
                    st.selected = st.selected.saturating_sub(1);
                    apply_selection(&mut st);
                }
                glib::Propagation::Stop
            }
            _ => glib::Propagation::Proceed,
        }
    });
    search.add_controller(ctrl);

    let state_c = state.clone();
    let win = window.clone();
    search.connect_activate(move |_| {
        let st = state_c.borrow();
        if let Some(&idx) = st.visible.get(st.selected) {
            if let Some(e) = st.entries.get(idx) {
                launch(&e.exec);
                win.close();
            }
        }
    });

    let win = window.clone();
    search.connect_stop_search(move |_| {
        win.close();
    });

    window.present();
    search.grab_focus();
}

fn main() {
    let app = Application::builder()
        .application_id("com.hypr.applauncher")
        .build();
    app.connect_activate(build_ui);
    app.run();
}
