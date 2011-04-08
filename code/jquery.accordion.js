jQuery.fn.accordion = function() {
  $(this)
    .addClass('accordion')
    .find('> :header:first')
      .addClass('accordion-open')
    .end()
    .find('> :not(:header):not(:first)')
      .hide()
    .end()
    .delegate('.accordion > :header', 'click', function() {
        $(this)
        .toggleClass('accordion-open')
        .next()
          .slideToggle(250)
        .end()
        .siblings('.accordion-open')
          .removeClass('accordion-open')
          .next()
            .slideUp(250);
      });

  return this;
};
