


SMODS.Atlas {
    -- Key for code to find it with
    key = "joker-sprites",
    -- The name of the file, for the code to pull the atlas from
    path = "joker-sprites.png",
    -- Width of each sprite in 1x size
    px = 71,
    -- Height of each sprite in 1x size
    py = 95
  }

  function pseudorandom_elements(_t, seed, count)
    if count >= #_t then
      return _t
    end


    if seed then math.randomseed(seed) end

    local keys = {}
    for k, v in pairs(_t) do
        keys[#keys+1] = {k = k,v = v}
    end

    for i = #keys, 2, -1 do
      local j = math.random(i)
      keys[i], keys[j] = keys[j], keys[i]
    end
  
    local shuffled = {}
    for key, value in pairs({unpack(keys, 1, count)}) do
      shuffled[key] = value.v
    end
  
    return shuffled
  end
  

  local function random_destroy(used_tarot)
    local destroyed_cards = {}
    destroyed_cards = pseudorandom_elements(G.hand.cards, pseudoseed('random_destroy'), 5)

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.4,
        func = function()
            play_sound('tarot1')
            used_tarot:juice_up(0.3, 0.5)
            return true
        end
    }))
    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.1,
        func = function()
            for i = #destroyed_cards, 1, -1 do
                local card = destroyed_cards[i]
                if card.ability.name == 'Glass Card' then
                    card:shatter()
                else
                    card:start_dissolve(nil, i ~= #destroyed_cards)
                end
            end
            return true
        end
    }))
    return destroyed_cards
  end

  
  SMODS.Joker {
    key = 'my-joker',
    loc_txt = {
      name = 'My Custom Joker',
      text = {
        "My custom description"
      }
    },
    config = { 
        extra = { 
            consumed_cards = {},
            hands_played = 0,
            
        
        } },
    loc_vars = function(self, info_queue, card)
      return { vars = { } }
    end,
    rarity = 1,
    atlas = 'joker-sprites',
    pos = { x = 0, y = 0 },
    cost = 2,
    calculate = function(self, card, context)
      -- Tests if context.joker_main == true.
      -- joker_main is a SMODS specific thing, and is where the effects of jokers that just give +stuff in the joker area area triggered, like Joker giving +Mult, Cavendish giving XMult, and Bull giving +Chips.
      if context.joker_main then
        return {
          mult_mod = card.ability.extra.hands_played,
          message = localize { type = 'variable', key = 'a_mult', vars = { card.ability.extra.hands_played } }
        }
      end

      if context.after and context.cardarea == G.jokers then 
        -- local random_card = pseudorandom_element(G.hand.cards, pseudoseed('random_destroy'))
        -- sendInfoMessage(random_card.base.value, "My Debug Card Value")
        local destroyed_cards = random_destroy(card)
        card.ability.extra.hands_played = card.ability.extra.hands_played + 1
        -- SMODS.calculate_context({ remove_playing_cards = true, removed = destroyed_cards })
        return {
            message = 'Upgraded!',
            colour = G.C.CHIPS,
            card = card
          }
      end
    end
  }