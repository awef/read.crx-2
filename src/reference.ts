interface SelectableItemList {
  select (target:number):void;
  select (target:HTMLElement):void;

  getSelected ():HTMLElement;

  clearSelect ():void;

  selectPrev ():void;

  selectNext ():void;
}
