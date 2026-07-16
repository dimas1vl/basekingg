(function () {
    var hudEl         = document.getElementById('hud');
    var hudArmorFill  = document.getElementById('hud-armor-fill');
    var hudHealthFill = document.getElementById('hud-health-fill');
    var hudHealthVal  = document.getElementById('hud-health-value');
    var hudLeave      = document.getElementById('hud-leave');
    var hudLeaveFill  = document.getElementById('hud-leave-fill');

    function updateHud(d) {
        if (!hudEl) return;
        var hpPct    = d.hpMax    > 0 ? Math.max(0, Math.min(100, (d.hp    / d.hpMax)    * 100)) : 0;
        var armorPct = d.armorMax > 0 ? Math.max(0, Math.min(100, (d.armor / d.armorMax) * 100)) : 0;

        if (hudHealthFill) hudHealthFill.style.width = hpPct + '%';
        if (hudArmorFill)  hudArmorFill.style.width  = armorPct + '%';
        if (hudHealthVal)  hudHealthVal.textContent  = Math.round(d.hp);
    }

    window.addEventListener('message', function (event) {
        var msg = event.data || {};

        if (msg.action === 'lobby_minigames:hud:update') {
            updateHud(msg.data || {});
            return;
        }

        if (msg.action === 'lobby_minigames:hud:visible') {
            var v = !!(msg.data && msg.data.visible);
            if (hudEl) hudEl.hidden = !v;
            if (!v && hudLeave) {
                hudLeave.hidden = true;
                hudLeaveFill.style.width = '0%';
            }
            return;
        }

        if (msg.action === 'lobby_minigames:leaveHold') {
            var visible = !!msg.visible;
            var percent = Math.max(0, Math.min(100, Number(msg.percent) || 0));
            if (hudLeave) hudLeave.hidden = !visible;
            if (hudLeaveFill) hudLeaveFill.style.width = percent + '%';
            return;
        }
    });
})();
