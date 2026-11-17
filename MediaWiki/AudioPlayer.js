"use strict";
$(function () {
  $(".media-audio").each(function (i) {
    var file = $(this).data("file");
    var panel = $(this).data("panel") || "";
    var button = $(this).data("button") || "";
    var progress = $(this).data("progress") || "";
    var dot = $(this).data("dot") || "";
    var bar = $(this).data("bar") || "";
    var preload = $(this).data("preload") || "metadata";
    var isMini = $(this).data("mini") ? "is-mini" : "";

    var audio = $("<audio>").attr({
      src: file,
      preload: preload,
      id: "audio" + i
    });

    $(this).append(audio);
    $(this).append(`
      <div class="audio-controls ${isMini}" style="${panel}" ondragstart="return false">
        <div class="play-pause">
          <div class="icon-btn icon-play" style="${button}"></div>
        </div>
        <div class="play-time">
          <div class="progressBarBg" style="${progress}">
            <span class="progressDot" style="${dot}"></span>
            <div class="progressBar" style="${bar}"></div>
          </div>
        </div>
      </div>`);

    audio[0].addEventListener("play", pauseAll.bind(audio[0]));
    audio[0].addEventListener("timeupdate", updateProgress, false);
    audio[0].addEventListener("ended", audioEnded, false);
  });

  // 播放暂停切换逻辑
  $(".play-pause").on("click", function () {
    var $controls = $(this).closest(".audio-controls");
    var audio = $controls.siblings("audio")[0];
    if (audio.paused) {
      audio.play();
      $controls.addClass("is-playing");
      $(this).find(".icon-btn").removeClass("icon-play").addClass("icon-pause");
    } else {
      audio.pause();
      $controls.removeClass("is-playing");
      $(this).find(".icon-btn").removeClass("icon-pause").addClass("icon-play");
    }
  });

  var isDragging = false;
  var currentAudio = null;

  // 统一进度计算函数
  function setProgress(e, $playTime) {
    var audio = $playTime.closest(".audio-controls").siblings("audio")[0];
    var rect = $playTime[0].getBoundingClientRect();
    
    // 获取点击/触摸位置相对于进度条左侧的偏移
    var pageX = e.type.indexOf('touch') !== -1 ? e.originalEvent.touches[0].pageX : e.pageX;
    var offset = pageX - rect.left;
    var width = rect.width;
    
    // 限制范围在 0 到 总宽之间
    offset = Math.max(0, Math.min(offset, width));
    
    var percentage = offset / width;
    audio.currentTime = percentage * audio.duration;
    
    // 立即更新 UI
    $playTime.find(".progressDot").css("left", (percentage * 100) + "%");
    $playTime.find(".progressBar").css("width", (percentage * 100) + "%");
  }

  // 进度条交互
  $(".play-time").on("mousedown touchstart", function (e) {
    isDragging = true;
    currentAudio = $(this).closest(".audio-controls").siblings("audio").attr("id");
    setProgress(e, $(this));
  });

  $(window).on("mousemove touchmove", function (e) {
    if (isDragging) {
      var $activePlayTime = $("#" + currentAudio).siblings(".audio-controls").find(".play-time");
      setProgress(e, $activePlayTime);
    }
  });

  $(window).on("mouseup touchend", function () {
    isDragging = false;
  });

  function updateProgress() {
    var audio = this;
    var percentage = (audio.currentTime / audio.duration) * 100;
    var $controls = $(audio).siblings(".audio-controls");
    $controls.find(".progressDot").css("left", percentage + "%");
    $controls.find(".progressBar").css("width", percentage + "%");
  }

  function audioEnded() {
    $(this).siblings(".audio-controls").removeClass("is-playing")
           .find(".icon-btn").removeClass("icon-pause").addClass("icon-play");
    updateProgress.call(this);
  }

  function pauseAll() {
    var self = this;
    $("audio").each(function() {
      if (this !== self) {
        this.pause();
        $(this).siblings(".audio-controls").removeClass("is-playing")
               .find(".icon-btn").removeClass("icon-pause").addClass("icon-play");
      }
    });
  }
});