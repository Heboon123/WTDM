tdiv {
  flow:t='horizontal'
  height:t='357@sf/@pf'
  <<#offers>>
  <<#needSeparator>>
  separator {
    width:t='1@sf/@pf'
    height:t='310@sf/@pf'
    margin-top:t='67@sf/@pf'
    background-color:t='#FFFFFF'
    color-factor:t='76'
  }
  <</needSeparator>>
  tdiv {
    flow:t='vertical'
    textareaNoTab {
      position:t='relative'
      pos:t='0.5pw-0.5w, 0'
      margin:t='0, 20@sf/@pf'
      mediumFont:t="yes"
      overlayTextColor:t='userlog'
      text:t='<<title>>'
    }
    tdiv {
      flow:t='horizontal'
      <<#items>>
      tdiv {
        position:t='relative'
        pos:t='0, -20@sf/@pf'
        margin='60@sf/@pf, 0'
        tdiv {
          flow:t='vertical'
          tdiv {
            size:t='154@sf/@pf, 154@sf/@pf'
            position:t='relative'
            pos:t='0.5pw-0.5w, 0'
            imagePlace {
              pos:t='pw/2-w/2, ph/2-h/2'
              position:t='absolute'
              <<@image>>
            }
            textareaNoTab {
              pos:t='pw-w, ph-h'
              position:t='absolute'
              smallFont:t="yes"
              overlayTextColor:t='active'
              text:t='<<count>>'
            }
          }
          textareaNoTab {
            pos:t='0.5pw-0.5w, 0'
            position:t='relative'
            max-width:t='242@sf/@pf'
            margin-top:t='4@sf/@pf'
            text-align:t='center'
            overlayTextColor:t='active'
            text:t='<<description>>'
          }
          <<#cost>>
          tdiv {
            pos:t='0.5pw-0.5w, 234@sf/@pf'
            position:t='absolute'
            flow:t='horizontal'
            textareaNoTab {
              smallFont:t="no"
              overlayTextColor:t='active'
              text:t='<<cost>>'
              color-factor:t='153'
              redLine {
                width:t='1.1pw'
                height:t='2@sf/@pf'
                pos:t='pw/2 - w/2, ph/2 - h/2'
                position:t='absolute'
                background-color:t='@red'
              }
            }
            textareaNoTab {
              margin-left:t='10@sf/@pf'
              smallFont:t="no"
              overlayTextColor:t='active'
              text:t='<<discountCost>>'
            }
          }
          <</cost>>
          <<#canPreview>>
          Button_text {
            pos:t='0.5pw-0.5w, 310@sf/@pf - h'
            position:t='absolute'
            text:t='#mainmenu/btnPreview'
            tooltip:t='<<btnTooltip>>'
            btnName:t='L3'
            on_click:t='<<funcName>>'
            showButtonImageOnConsole:t='no'
            class:t='image'
            img{ background-image:t='#ui/gameuiskin#btn_preview.svg' }
            <<@actionParamsMarkup>>
          }
          <</canPreview>>
        }
      }
      <</items>>
      <<#units>>
      tdiv {
        margin='60@sf/@pf, 0'
        tdiv {
          flow:t='vertical'
          tdiv {
            size:t='195@sf/@pf, 80@sf/@pf'
            tdiv {
              pos:t='pw/2-w/2, ph/2-h/2'
              position:t='absolute'
              size:t='pw, ph'
              img {
                position:t='absolute'
                size:t='pw, 0.5pw';
                background-svg-size:t='pw, 0.5pw';
                background-image:t='<<image>>'
                tooltip:t='$tooltipObj'
                tooltipObj {
                tooltipId:t='<<tooltipId>>'
                  display:t='hide'
                  on_tooltip_open:t='onGenericTooltipOpen';
                  on_tooltip_close:t='onTooltipObjClose';
                }
                <<#inWishlist>>
                tdiv {
                  position:t='absolute'
                  pos:t='0, ph-1.5h'
                  flow:t='horizontal'
                  img {
                    size:t='@sIco, @sIco'
                    background-svg-size:t='@sIco, @sIco'
                    background-image:t='#ui/gameuiskin#open_wishlist.svg'
                  }
                  textareaNoTab {
                    margin-left:t='0.5@blockInterval'
                    overlayTextColor:t='userlog'
                    tinyFont:t='yes'
                    text:t='#specialOffer/inWishlist'
                    valign:t='center'
                  }
                }
                <</inWishlist>>
              }
            }
          }
          tdiv {
            margin-top:t='16@sf/@pf'
            height:t='28@sf/@pf'
            flow:t='horizontal'
            position:t='relative'
            tdiv {
              size:t='40@sf/@pf, 40@sf/@pf'
              position:t='relative'
              pos:t='0, ph/2-h/2'
              background-color:t='@white'
              background-image:t='<<countryIco>>'
            }
            tdiv {
              margin-left:t='12@sf/@pf'
              height:t='ph'
              textareaNoTab {
                margin-top:t='ph-h'
                position:t='relative'
                normalBoldFont:t="yes"
                overlayTextColor:t='active'
                text:t='<<br>>'
                css-hier-invalidate:t='yes'
              }
              textareaNoTab {
                margin-left:t='4@sf/@pf'
                pos:t='0, ph-h+2@sf/@pf'
                position:t='relative'
                tinyFont:t="yes"
                overlayTextColor:t='active'
                text:t='#mainmenu/brText'
                css-hier-invalidate:t='yes'
              }
            }
          }
          tdiv {
            margin-top:t='14@sf/@pf'
            position:t='relative'
            max-width:t='280@sf/@pf'
            overflow:t='hidden'
            textareaNoTab {
              overlayTextColor:t='active'
              text:t='<<unitFullName>>'
              behaviour:t='OverflowScroller'
              move-pixel-per-sec:t='20*@scrn_tgt/100.0'
              move-sleep-time:t='1000'
              move-delay-time:t='1000'
            }
          }
          textareaNoTab {
            tinyFont:t="yes"
            text:t='<<unitType>>'
          }
          textareaNoTab {
            margin-top:t='7@sf/@pf'
            smallFont:t="yes"
            overlayTextColor:t='active'
            text:t='<<unitRank>>'
          }
          <<#cost>>
          tdiv {
            pos:t='0, 214@sf/@pf'
            position:t='absolute'
            flow:t='horizontal'
            textareaNoTab {
              smallFont:t="no"
              overlayTextColor:t='active'
              text:t='<<cost>>'
              color-factor:t='153'
              redLine {
                width:t='1.1pw'
                height:t='2@sf/@pf'
                pos:t='pw/2 - w/2, ph/2 - h/2'
                position:t='absolute'
                background-color:t='@red'
              }
            }
            textareaNoTab {
              margin-left:t='10@sf/@pf'
              smallFont:t="no"
              overlayTextColor:t='active'
              text:t='<<discountCost>>'
            }
          }
          <</cost>>
          Button_text {
            pos:t='0, 290@sf/@pf - h'
            position:t='absolute'
            text:t='#mainmenu/btnPreview'
            tooltip:t='<<btnTooltip>>'
            btnName:t='L3'
            on_click:t='<<funcName>>'
            showButtonImageOnConsole:t='no'
            class:t='image'
            img{ background-image:t='#ui/gameuiskin#btn_preview.svg' }
            <<@actionParamsMarkup>>
          }
        }
      }
      <</units>>
    }
  }
  <</offers>>
}