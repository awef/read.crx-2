(function($) {
  var uid,
      tab_init, tab_add, tab_remove, tab_select;

  uid = (function() {
    var count = 0;
    return function() { return 'tab_id_' + (++count); };
  })();

  tab_init = function() {
    var that = this;
    $(this)
      .addClass('tab')
      .append('<ul class="tab_tabbar">', '<div class="tab_container">')
      .delegate('.tab_tabbar', 'mousewheel', function(e) {
          var way, next;

          e.preventDefault();
          way = e.wheelDelta > 0 ? 'prev' : 'next';
          next = $(that).find('.tab_tabbar li.tab_selected')[way]();
          if (next.length === 1) {
            tab_select.call(that, {tab_id: next.attr('data-tab_id')});
          }
        })
      .delegate('.tab_tabbar li', 'mousedown', function(e) {
          (e.which === 2 ? tab_remove : tab_select)
            .call(that, {tab_id: $(this).attr('data-tab_id')});
        })
      .delegate('.tab_tabbar img', 'click', function() {
        console.log(this);
          tab_remove.call(
              that,
              {tab_id: $(this).parent().attr('data-tab_id')}
          );
        });
  };
  // prop.element, prop.title, [prop.background]
  tab_add = function(prop) {
    var $this = $(this), tab_id = uid();

    $('<li>', {'data-tab_id': tab_id, title: prop.title})
      .append($('<span>', {text: prop.title}))
      .append($('<img>', {src: '/img/close_16x16.png', title: '閉じる'}))
      .appendTo($this.find('.tab_tabbar'));

    $(prop.element)
      .attr('data-tab_id', tab_id)
      .appendTo($this.find('.tab_container'));

    if (!prop.background || $this.find('.tab_tabbar li').length !== 1) {
      tab_select.call(this, {tab_id: tab_id});
    }
  };
  // prop.tab_id
  tab_remove = function(prop) {
    var that = this;

    $(this)
      .find('[data-tab_id="' + prop.tab_id + '"]')
        .filter('.tab_tabbar li.tab_selected')
          .each(function() {
              var $this = $(this), next;

              next = $this.prev('li').add($this.next('li'));
              if (next.length) {
                tab_select.call(that, {tab_id: next.attr('data-tab_id')});
              }
            })
          .end()
       .remove();
  };
  // prop.tab_id
  tab_select = function(prop) {
    $(this)
      .find('.tab_selected')
        .removeClass('tab_selected')
      .end()
      .find('[data-tab_id="' + prop.tab_id + '"]')
        .addClass('tab_selected')
        .filter('.tab_container *')
          .trigger('tab_selected');
  };

  $.fn.tab = function(method, prop) {
    ({
      init: tab_init,
      add: tab_add,
      remove: tab_remove,
      select: tab_select
    })[method || 'init'].call(this, prop || {});
    return this;
  };
})(jQuery);
