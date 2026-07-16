let currentType = "checkpoint";
let currentDistance = null;
const resourceName =
    typeof GetParentResourceName === "function"
        ? GetParentResourceName()
        : window.location.hostname;

function hideAll() {
    document.querySelectorAll(".marker-type").forEach((element) => {
        element.style.display = "none";
    });
}

function showCurrent() {
    if (!currentType) {
        return;
    }

    const marker = document.getElementById(`marker-${currentType}`);
    if (marker) {
        marker.style.display = "flex";
    }
}

function animateDistance(newValue, duration = 90) {
    const element = document.getElementById("small-distance-value");
    if (!element) return;
    const start = parseFloat(currentDistance);
    const end = parseFloat(newValue);
    const startTime = performance.now();

    function animate(currentTime) {
        const elapsed = currentTime - startTime;
        const t = Math.min(elapsed / duration, 1);
        const easedT = t * t * (3 - 2 * t);
        const value = start + (end - start) * easedT;
        element.textContent = Math.round(value);
        if (t < 1) {
            requestAnimationFrame(animate);
        } else {
            currentDistance = newValue;
        }
    }

    requestAnimationFrame(animate);
}

export async function fetchNui(eventName, data) {
    const resp = await fetch(`https://${resourceName}/${eventName}`, {
        method: "post",
        headers: {
            "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify(data),
    });

    const text = await resp.text();
    return text ? JSON.parse(text) : {};
}

function setDistance(value) {
    const text = String(value ?? "0");
    const el = document.getElementById("small-distance-value");
    if (el) el.textContent = text;
}

function setLabel(value) {
    const text = String(value || "DISTANCIA");
    document.getElementById("checkpoint-label").textContent = text;
    document.getElementById("small-label").textContent = text;
}

function setInteraction(data) {
    const keyText = document.getElementById("interaction-key-text");
    const action = document.getElementById("interaction-action");
    const detail = document.getElementById("interaction-detail");
    const detailValue = document.getElementById("interaction-detail-value");
    const detailRow = document.querySelector(".interaction-detail-row");

    if (data.key !== undefined && keyText) keyText.textContent = String(data.key || "");
    if (data.actionText !== undefined) action.textContent = String(data.actionText || "");
    if (data.detail !== undefined) detail.textContent = String(data.detail || "");
    if (data.detailValue !== undefined) detailValue.textContent = String(data.detailValue || "");

    const hasDetail = Boolean(data.detail || data.detailValue);
    if (detailRow) {
        detailRow.style.display = hasDetail ? "flex" : "none";
    }
}

function setColor(value) {
    document.documentElement.style.setProperty("--marker-color", value || "#f4d000");
}

function showDistance(show) {
    const display = show ? "flex" : "none";
    const el = document.getElementById("small-distance");
    if (el) el.style.display = display;
}

function reset() {
    currentType = "checkpoint";
    currentDistance = null;
    setColor("#f4d000");
    setDistance("0");
    setLabel("DISTANCIA");
    showDistance(true);
    setInteraction({ key: "E", action: "", detail: "", detailValue: "" });
    const bar = document.querySelector(".hold-progress-bar");
    if (bar) bar.style.strokeDashoffset = 100;
    hideAll();
}

window.addEventListener("message", (event) => {
    const data = event.data;
    if (!data || !data.action) {
        return;
    }

    switch (data.action) {
        case "load":
            fetchNui("load", { id: data.id });
            break;

        case "setType":
            hideAll();
            currentType = data.type || "checkpoint";
            showCurrent();
            break;

        case "setColor":
            setColor(data.color);
            break;

        case "setIcon":
            // O design do rush-lab nao usa icones, entao ignoramos esta mensagem.
            break;

        case "setImage":
            // O design do rush-lab nao usa imagens, entao ignoramos esta mensagem.
            break;

        case "setLabel":
            setLabel(data.text);
            break;

        case "setInteraction":
            setInteraction(data);
            break;

        case "setDistance": {
            const newDist = data.value || "0";
            const duration = (data.duration || 100) - 10;
            if (!currentDistance || duration <= 50) {
                currentDistance = newDist;
                setDistance(newDist);
            } else {
                animateDistance(newDist, duration);
            }
            break;
        }

        case "showDistance":
            showDistance(Boolean(data.show));
            break;

        case "setHoldProgress": {
            const svg = document.querySelector(".hold-progress");
            const bar = document.querySelector(".hold-progress-bar");
            const row = document.querySelector(".interaction-row");
            if (svg && bar && row) {
                const w = row.offsetWidth;
                const h = row.offsetHeight;
                svg.setAttribute("viewBox", `0 0 ${w} ${h}`);
                bar.setAttribute("x", "1.5");
                bar.setAttribute("y", "1.5");
                bar.setAttribute("width", String(w - 3));
                bar.setAttribute("height", String(h - 3));
                const progress = Math.max(0, Math.min(1, data.progress ?? 0));
                bar.style.strokeDashoffset = 100 - progress * 100;
            }
            break;
        }

        case "hide":
            hideAll();
            break;

        case "show":
            showCurrent();
            break;

        case "reset":
            reset();
            break;
    }
});

reset();
