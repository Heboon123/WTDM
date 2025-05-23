<<#presets>>
weaponryPreset {
  id:t='preset'
  presetId:t='<<presetId>>'
  width:t='pw'
  padding-bottom:t='1@blockInterval'
  chosen:t='<<chosen>>'
  <<#isCollapsable>>
  height:t='@buttonHeight'
  collapse_header:t='yes'
  collapsed:t='no'
  collapsing:t='no'
  <</isCollapsable>>
  <<^isCollapsable>>
  height:t='@tierIconSize'
  <</isCollapsable>>

  tdiv {
    width:t='pw'
    position:t='absolute'
    <<#weaponryItem>>
    DummyButton {
      presetId:t='<<presetId>>'
      size:t='pw, @tierIconSize'
      position:t='absolute'
      skip-navigation:t='yes'
      on_click:t='onPresetSelect'
      on_dbl_click:t='onModItemDblClick'
    }
    tdiv {
      id:t='tiersNest_<<presetId>>'
      presetId:t='<<presetId>>'
      flow:t='horizontal'
      css-hier-invalidate:t='yes'
      total-input-transparent:t='yes'
      isContainer:t='yes'
      interactive:t='yes'
      shortcut-on-hover:t='yes'
      presetHeader {
        id:t='presetHeader_<<presetId>>'
        presetId:t='<<presetId>>'
        size:t='<<presetTextWidth>>, @tierIconSize'
        css-hier-invalidate:t='yes'
        <<^hideWarningIcon>>
        warning_icon{
          position:t='relative'
          size:t='@cIco, @cIco'
          background-image:t='#ui/gameuiskin#new_icon.svg'
          background-svg-size:t='@cIco, @cIco'
          bgcolor:t='#FFFFFF'
        }
        <</hideWarningIcon>>
        textareaNoTab {
          id:t='header_name_txt'
          width:t='pw<<^hideWarningIcon>>-1@cIco<</hideWarningIcon>>'
          position:t='relative'
          pos:t='0, 30@sf/@pf-0.5h'
          text:t='<<nameTextWithPrice>>'
          text-align:t='left'
          style:t='color:@<<itemTextColor>>;'
          smallFont:t='yes'
          <<#hideWarningIcon>>
          padding:t='1@blockInterval, 0'
          <</hideWarningIcon>>
        }
        img{
          id:t='image'
          size:t='pw-2@weaponIconPadding, ph-2@weaponIconPadding'
          pos:t='50%pw-50%w, 50%ph-50%h'
          position:t='absolute'

          <<@modUpgradeIcon>>
          upgradeImg {
            id:t='upgrade_img'
            upgradeStatus:t=''
          }
        }
        focus_border {}
      }
      <<#tiersView>>
      weaponryTier{
        id:t='tier_<<tierId>>'
        tierId:t='<<tierId>>'
        size:t='@tierIconSize, @tierIconSize'
        <<^isActive>>enable:t='no'<</isActive>>
        interactive:t='yes'
        shortcut-on-hover:t='yes'
        img {
          size:t='@tierIconSize, @tierIconSize'
          position:t='relative'
          background-image:t='<<#img>><<img>><</img>>'
          background-repeat:t='expand'
          background-svg-size:t='@tierIconSize, @tierIconSize'
        }
        <<#tierTooltipId>>
        title:t='$tooltipObj'
        tooltip-float:t='horizontal'
        tooltipObj {
          id:t='tierTooltip'
          tooltipId:t='<<tierTooltipId>>'
          on_tooltip_open:t='onGenericTooltipOpen'
          on_tooltip_close:t='onTooltipObjClose'
          display:t='hide'
        }
        <</tierTooltipId>>
        focus_border {}
      }
      <</tiersView>>
    }
    <</weaponryItem>>
  }

  <<#isCollapsable>>
  fullSizeCollapseBtn {
    size:t='pw, ph'
    total-input-transparent:t='yes'
    input-transparent:t='no'
    css-hier-invalidate:t='yes'
    on_click:t='onCollapse'
    isNavInContainerBtn:t='yes'
    activeText{}
    ButtonImg {}
    text {
      position:t='relative'
      pos:t='<<chapterPos>>-0.5w-1@sIco, 0'
      text:t='<<chapterName>>'
    }
  }
  <</isCollapsable>>
}
<</presets>>