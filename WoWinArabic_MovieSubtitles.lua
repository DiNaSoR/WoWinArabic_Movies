-- Addon: WoWinArabic-Movies (version: 10.00) 2023.02.05
-- Note: AddOn displays translated subtitles during playing cinematics or movies.
-- Autor: Platine  (e-mail: platine.wow@gmail.com)
-- Special thanks for DragonArab for helping to create letter reshaping rules.


-- General Variables
local MF_version = GetAddOnMetadata("WoWinArabic_Movies", "Version");
local MF_name = UnitName("player");
local MF_race = UnitRace("player");
local MF_class = UnitClass("player");
local MF_movieID, MF_SubTitle, MF_lp, MF_ID, MF_playing, MF_showing, MF_timer, MF_time1, MF_last_ST, MF_pytanie1, MF_pytanie2;
if (MF_class == "Death Knight") then
   MF_race = MF_class;
end

-- fonty z arabskimi znakami diakrytycznymi
local MF_Font = "Interface\\AddOns\\WoWinArabic_Movies\\Fonts\\calibri.ttf";
local MF_Size = 16;

-------------------------------------------------------------------------------------------------------

local function StringHash(text)           -- funkcja tworząca Hash (32-bitowa liczba) podanego tekstu
  local counter = 1;
  local pomoc = 0;
  local dlug = string.len(text);
  for i = 1, dlug, 3 do 
    counter = math.fmod(counter*8161, 4294967279);  -- 2^32 - 17: Prime!
    pomoc = (string.byte(text,i)*16776193);
    counter = counter + pomoc;
    pomoc = ((string.byte(text,i+1) or (dlug-i+256))*8372226);
    counter = counter + pomoc;
    pomoc = ((string.byte(text,i+2) or (dlug-i+256))*3932164);
    counter = counter + pomoc;
  end
  return math.fmod(counter, 4294967291) -- 2^32 - 5: Prime (and different from the prime in the loop)
end

-------------------------------------------------------------------------------------------------------

local function RenderujKody(txt)       -- do zapisu nieznanych tekstów
   txt = string.gsub(txt, UnitName("player"), "$N");
   txt = string.gsub(txt, string.upper(UnitName("player")), "$N$");
   txt = string.gsub(txt, UnitRace("player"), "$R");
   txt = string.gsub(txt, string.lower(UnitRace("player")), "$R");
   txt = string.gsub(txt, UnitClass("player"), "$C");
   txt = string.gsub(txt, string.lower(UnitClass("player")), "$C");
   return txt;
end

-------------------------------------------------------------------------------------------------------

local function MF_ZmienKody(message)
   message = string.gsub(message, "$n$", AS_UTF8reverse(string.upper(MF_name)));    -- i trzeba ją zamienić na nazwę gracza
   message = string.gsub(message, "$N$", AS_UTF8reverse(string.upper(MF_name)));    -- tu jeszcze pisane DUŻYMI LITERAMI
   message = string.gsub(message, "$n", AS_UTF8reverse(MF_name));
   message = string.gsub(message, "$N", AS_UTF8reverse(MF_name));
   message = string.gsub(message, "$r", AS_UTF8reverse(MF_race));  
   message = string.gsub(message, "$R", AS_UTF8reverse(MF_race));
   message = string.gsub(message, "$c", AS_UTF8reverse(MF_class));    
   message = string.gsub(message, "$C", AS_UTF8reverse(MF_class));
   return message;   
end

-------------------------------------------------------------------------------------------------------

local function MF_OnEvent(self, event, ...)
   if (event=="PLAY_MOVIE") then
      MF_movieID = ... ;
      if (MF_movieID) then
--         print("MF-uruchamiam movie ID="..MF_movieID);      
--         MovieFrame.CloseDialog:SetText("End movie?");
         if (MF_pytanie1 == nil) then
            MF_pytanie1 = MovieFrame.CloseDialog:CreateFontString(nil, "ARTWORK");
            MF_pytanie1:SetFontObject(GameFontNormal);
            MF_pytanie1:SetJustifyH("CENTER");
            MF_pytanie1:SetJustifyV("CENTER");
            MF_pytanie1:ClearAllPoints();
            MF_pytanie1:SetPoint("CENTER", MovieFrame.CloseDialog, "CENTER", 0, 6);
            MF_pytanie1:SetFont(MF_Font, 16);
            MF_pytanie1:SetText(AS_UTF8reverse("إنهاء الفيلم؟"));
         end
         MovieFrame:EnableSubtitles(true);      -- włącz wyświetlanie napisów
         MF_last_ST = "";
         MF_lp = 0;
         MF_ID = tostring(MF_movieID);
         while (string.len(MF_ID)<3) do
            MF_ID = "0"..MF_ID;
         end
         local _font, _size, _3 = MovieFrameSubtitleString:GetFont();
         MovieFrameSubtitleString:SetFont(MF_Font, _size);           -- arabskie czcionki do napisów
         MovieFrame:HookScript("OnMovieShowSubtitle", MF_ShowMovieSubtitles);
         MF_Size = _size + 3;          -- powiększamy czcionkę arabską o 3
      end
   elseif (event=="CINEMATIC_START") then
--      print("MF-uruchamiam cinematic");
--      CinematicFrameCloseDialog:SetText("End movie?");
      if (MF_pytanie2 == nil) then
         MF_pytanie2 = CinematicFrameCloseDialog:CreateFontString(nil, "ARTWORK");
         MF_pytanie2:SetFontObject(GameFontNormal);
         MF_pytanie2:SetJustifyH("CENTER");
         MF_pytanie2:SetJustifyV("CENTER");
         MF_pytanie2:ClearAllPoints();
         MF_pytanie2:SetPoint("CENTER", CinematicFrameCloseDialog, "CENTER", 0, 6);
         MF_pytanie2:SetFont(MF_Font, 16);
         MF_pytanie2:SetText(AS_UTF8reverse("إنهاء الفيلم؟"));
      end
      MovieFrame:EnableSubtitles(false);      -- wyłącz wyświetlanie napisów oryginalnych?
      local _font, _size, _3 = MovieFrameSubtitleString:GetFont();   -- odczytaj wielkość czcionki
      _size = math.floor(_size+.5)+3;
      CinematicFrame.Subtitle1:SetFont(MF_Font, _size);              -- zmień czcionkę na arabską
      if (((UnitLevel("player")==1) and (C_Map.GetBestMapForUnit("player")~=1409) and (C_Map.GetBestMapForUnit("player")~=1726) and (C_Map.GetBestMapForUnit("player")~=1727)) or ((MF_class == "Death Knight") and (UnitLevel("player")==8))) then
         MF_SubTitle = CinematicFrame:CreateFontString(nil, "ARTWORK");    -- mamy Cinematic INTRO, ale nie z nowego zone: Exile's Reach, ani The North Sea                                      kraina: 124
         MF_SubTitle:SetFontObject(GameFontNormalLarge);
         MF_SubTitle:SetJustifyH("CENTER"); 
         MF_SubTitle:SetJustifyV("MIDDLE");
         MF_SubTitle:ClearAllPoints();
         MF_SubTitle:SetPoint("CENTER", CinematicFrame, "BOTTOM", 0, 65);
         MF_SubTitle:SetText("");
         MF_SubTitle:SetFont(MF_Font, 22);
         MF_playing = false;
         MF_lp = 1;
         MF_showing = false;
         if (MF_Data[MF_race..":01"]) then
            MF_sub1 = MF_Data[MF_race..":01"]["START"];
            MF_sub2 = MF_Data[MF_race..":01"]["STOP"];
            MF_sub3 = MF_Data[MF_race..":01"]["NAPIS"];
            CinematicFrame:HookScript("OnUpdate", MF_ShowCinematicIntro);
         end
      else                                      -- mamy cinematic on game
         CinematicFrame:HookScript("OnUpdate", MF_ShowCinematicSubtitles);
         MF_time1 = GetTime();
      end      
   elseif (event=="CINEMATIC_STOP") then
      CinematicFrame:SetScript("OnUpdate", nil);
      -- wyłącz napisy
      if (MF_SubTitle) then
         MF_SubTitle:Hide();
      end
   end
end

-------------------------------------------------------------------------------------------------------

function MF_ShowMovieSubtitles()             -- wyświetlanie napisów w MOVIES
   local MF_readed_ST = MovieFrameSubtitleString:GetText();
   if (MF_readed_ST ~= MF_last_ST) then      -- napis jest inny niż ostatni
      MF_last_ST = MF_readed_ST;             -- zapisz jako ostatni napis
      MF_hash = StringHash(MF_readed_ST);
      if (MF_Hash[MF_hash]) then             -- jest w bazie tłumaczenie napisu nr MF_lp
         MovieFrameSubtitleString:SetText(AS_UTF8reverse(MF_Hash[MF_hash]));
         MovieFrameSubtitleString:SetFont(MF_Font, MF_Size); 
      end
   end
end

-------------------------------------------------------------------------------------------------------

function MF_ShowCinematicSubtitles()            -- wyświetlanie napisów w CINEMATIC
   if (GetTime() - MF_time1 > 0.25) then        -- minęło conajmniej 0.25 sek.
      if (CinematicFrame.Subtitle1 and CinematicFrame.Subtitle1:IsVisible()) then        -- jest widoczny napis
         local MF_napis = CinematicFrame.Subtitle1:GetText();     -- odczytaj napis angielski
         MF_time1 = GetTime() + 1;                             -- +1 sek. nie trzeba sprawdzać
         local MF_hash = StringHash(MF_napis);                 -- zrób Hash z tego tekstu
         local p1, p2 = string.find(MF_napis,":");             -- poszukaj znaku ':'
         if (p1 and (p1>0) and (p1<30)) then         -- jest znak ':' w początkowej części napisu (NPC says:)
            local MF_napis2 = RenderujKody(string.sub(MF_napis, p1+2));
            local MF_hash2 = StringHash(MF_napis2);
            if (BB_Bubbles[MF_hash2]) then            -- istnieje tłumaczenie w dymkach
            
               local MF_output = "r|"..AS_UTF8reverse(string.sub(MF_napis,1,p1-1)).." مووي:FFEEDDCCc| "..MF_ZmienKody(BB_Bubbles[MF_hash2]);
               CinematicFrame.Subtitle1:SetText(AS_UTF8reverse(MF_output));                   -- podmień wyświetlany tekst
               if (string.len(MF_output) > 130) then
                  CinematicFrame.Subtitle1:SetFont(MF_Font, 15);         -- zmień czcionkę
               elseif (string.len(MF_output) > 120) then
                  CinematicFrame.Subtitle1:SetFont(MF_Font, 16);         -- zmień czcionkę
               elseif (string.len(MF_output) > 100) then
                  CinematicFrame.Subtitle1:SetFont(MF_Font, 18);         -- zmień czcionkę
               elseif (string.len(MF_output) > 80) then
                  CinematicFrame.Subtitle1:SetFont(MF_Font, 20);         -- zmień czcionkę
               else
                  CinematicFrame.Subtitle1:SetFont(MF_Font, 22);         -- zmień czcionkę
               end
            end
         else
            if (BB_Bubbles[MF_hash]) then            -- istnieje tłumaczenie w dymkach
               local _font, _size, _3 = CinematicFrame.Subtitle1:GetFont();   -- odczytaj wielkość czcionki
               CinematicFrame.Subtitle1:SetText(AS_UTF8reverse(MF_ZmienKody(BB_Bubbles[MF_hash])));  -- podmień wyświetlany tekst
               if (string.len(MF_output) > 130) then
                  CinematicFrame.Subtitle1:SetFont(MF_Font, 15);         -- zmień czcionkę
               elseif (string.len(MF_output) > 120) then
                  CinematicFrame.Subtitle1:SetFont(MF_Font, 16);         -- zmień czcionkę
               elseif (string.len(MF_output) > 100) then
                  CinematicFrame.Subtitle1:SetFont(MF_Font, 18);         -- zmień czcionkę
               elseif (string.len(MF_output) > 80) then
                  CinematicFrame.Subtitle1:SetFont(MF_Font, 20);         -- zmień czcionkę
               else
                  CinematicFrame.Subtitle1:SetFont(MF_Font, 22);         -- zmień czcionkę
               end
            end
         end
      end
   end
end

-------------------------------------------------------------------------------------------------------

function MF_ShowCinematicIntro()    -- wyświetlanie własnych napisów w INTRO
   if (MF_playing==false) then         
      MF_timer = GetTime();         -- wystartuj zegar filmu
      MF_playing=true;
   end
   if ((MF_showing==false) and (GetTime() > (MF_timer + MF_sub1))) then      -- czas wystartować napis
      MF_SubTitle:SetText(AS_UTF8reverse(MF_sub3));
      MF_showing=true;
   end      
   if ((MF_showing==true) and (GetTime() > (MF_timer + MF_sub2))) then       -- czas zatrzymać napis
      MF_SubTitle:SetText("");
      -- ładuj następny
      MF_showing=false;
      MF_lp = MF_lp + 1;
      local MF_lpSTR = tostring(MF_lp);
      if (MF_lp<10) then
         MF_lpSTR = "0"..MF_lpSTR;
      end
      if (MF_Data[MF_race..":"..MF_lpSTR]) then
         MF_sub1 = MF_Data[MF_race..":"..MF_lpSTR]["START"];
         MF_sub2 = MF_Data[MF_race..":"..MF_lpSTR]["STOP"];
         MF_sub3 = MF_ZmienKody(MF_Data[MF_race..":"..MF_lpSTR]["NAPIS"]);
      else
         MF_sub1=1000;
         MF_sub2=1000;
      end
   end          
end

-------------------------------------------------------------------------------------------------------

MF_Frame = CreateFrame("Frame");
MF_Frame:SetScript("OnEvent", MF_OnEvent);
MF_Frame:RegisterEvent("PLAY_MOVIE");
MF_Frame:RegisterEvent("CINEMATIC_START");
MF_Frame:RegisterEvent("CINEMATIC_STOP");

DEFAULT_CHAT_FRAME:AddMessage("|cffffff00WoWinArabic-Movies ver. "..MF_version.." - started");
