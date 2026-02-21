pragma Singleton

import qs.config
import qs.utils
import Caelestia
import Quickshell

Searcher {
    id: root

    function launch(entry: DesktopEntry): void {
        appDb.incrementFrequency(entry.id);

        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: ["app2unit", "--", ...Config.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        else
            Quickshell.execDetached({
                command: ["app2unit", "--", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
    }

    function search(search: string): list<var> {
        const prefix = Config.launcher.specialPrefix;

        if (search.startsWith(`${prefix}i `)) {
            keys = ["id", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}c `)) {
            keys = ["categories", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}d `)) {
            keys = ["comment", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}e `)) {
            keys = ["execString", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}w `)) {
            keys = ["startupClass", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}g `)) {
            keys = ["genericName", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}k `)) {
            keys = ["keywords", "name"];
            weights = [0.9, 0.1];
        } else {
            keys = ["name"];
            weights = [1];

            if (!search.startsWith(`${prefix}t `))
                return query(search).map(e => e.entry);
        }

        const results = query(search.slice(prefix.length + 2)).map(e => e.entry);
        if (search.startsWith(`${prefix}t `))
            return results.filter(a => a.runInTerminal);
        return results;
    }

    function selector(item: var): string {
        return keys.map(k => item[k]).join(" ");
    }

    list: appDb.apps
    useFuzzy: Config.launcher.useFuzzy.apps

    function categorized(customCategories, appCategoryOverrides, categoryRenames): list<var> {
        const apps = appDb.apps;
        const mapping = {
            "Development": "效率与财务",
            "Office": "效率与财务",
            "Education": "效率与财务",
            "Science": "效率与财务",
            "AudioVideo": "娱乐",
            "Audio": "娱乐",
            "Video": "娱乐",
            "Game": "娱乐",
            "Network": "社交",
            "Settings": "工具",
            "System": "工具",
            "Utility": "工具",
            "Graphics": "创意"
        };

        const overrides = appCategoryOverrides ?? {};
        const extraCats = customCategories ?? [];
        const renames = categoryRenames ?? {};

        // Apply renames to the mapping values
        function displayName(label) {
            return renames[label] ?? label;
        }

        const groups = {};
        const otherApps = [];

        for (const app of apps) {
            const appId = app.entry?.id ?? app.id ?? "";

            // Check user override first
            if (overrides[appId]) {
                const targetCat = overrides[appId];
                if (!groups[targetCat]) groups[targetCat] = [];
                groups[targetCat].push(app.entry);
                continue;
            }

            let found = false;
            let cats = [];
            if (typeof app.categories === "string") {
                cats = app.categories.split(/\s+/);
            } else if (Array.isArray(app.categories)) {
                cats = app.categories;
            }

            for (const cat of cats) {
                if (mapping[cat]) {
                    const dn = displayName(mapping[cat]);
                    if (!groups[dn]) groups[dn] = [];
                    groups[dn].push(app.entry);
                    found = true;
                    break;
                }
            }
            if (!found) {
                const otherDn = displayName("其他");
                if (!groups[otherDn]) groups[otherDn] = [];
                groups[otherDn].push(app.entry);
            }
        }

        const result = [{ label: "全部应用", apps: apps.map(app => app.entry) }];

        // Built-in categories (with display names)
        const builtInOrder = ["效率与财务", "娱乐", "社交", "工具", "创意"];
        for (const bi of builtInOrder) {
            const dn = displayName(bi);
            if (groups[dn]) {
                result.push({ label: dn, apps: groups[dn] });
                delete groups[dn];
            }
        }

        // "其他" with display name
        const otherDn = displayName("其他");
        const otherGroup = groups[otherDn];
        delete groups[otherDn];

        // Remaining groups (custom categories or override targets)
        for (const label in groups) {
            result.push({ label: label, apps: groups[label] });
        }

        // Custom user categories (even if empty, show them)
        for (const catName of extraCats) {
            if (!groups[catName] && !result.find(r => r.label === catName)) {
                result.push({ label: catName, apps: [] });
            }
        }

        if (otherGroup && otherGroup.length > 0) {
            result.push({ label: otherDn, apps: otherGroup });
        }
        return result;
    }

    AppDb {
        id: appDb

        path: `${Paths.state}/apps.sqlite`
        favouriteApps: Config.launcher.favouriteApps
        entries: DesktopEntries.applications.values.filter(a => !Strings.testRegexList(Config.launcher.hiddenApps, a.id))
    }
}
