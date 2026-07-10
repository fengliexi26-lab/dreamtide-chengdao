$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$KeywordNingmeng = [string]::Concat([char]0x51DD, [char]0x68A6)
$KeywordRetain = [string]::Concat([char]0x4FDD, [char]0x7559)
$TextGainFormationA = [string]::Concat([char]0x83B7, [char]0x5F97, " 1 ", [char]0x9635, [char]0x52BF)
$TextGainFormationB = [string]::Concat([char]0x83B7, [char]0x5F97, " 1 ", [char]0x70B9, [char]0x9635, [char]0x52BF)

function Read-Json($Path) {
    $fullPath = Join-Path $ProjectRoot $Path
    return Get-Content -Path $fullPath -Encoding UTF8 | ConvertFrom-Json
}

function Get-CardText($Card) {
    $parts = @()
    foreach ($field in @("effect_text", "description", "text")) {
        if ($null -ne $Card.$field) {
            $parts += [string]$Card.$field
        }
    }
    return ($parts -join " ")
}

function Has-Keyword($Card, [string[]]$Keywords) {
    if ($null -ne $Card.keywords) {
        foreach ($keyword in $Card.keywords) {
            if ($Keywords -contains [string]$keyword) {
                return $true
            }
        }
    }
    $text = Get-CardText $Card
    foreach ($keyword in $Keywords) {
        if ($text.Contains($keyword)) {
            return $true
        }
    }
    return $false
}

function Is-FormationDirection($Card) {
    if ($null -ne $Card.formation_gain -and [int]$Card.formation_gain -gt 0) {
        return $true
    }
    $text = Get-CardText $Card
    return ($text.Contains($TextGainFormationA) -or $text.Contains($TextGainFormationB))
}

function Is-ChengdaoBeast($Card) {
    $cardType = [string]$Card.type
    $kind = [string]$Card.chengdao_kind
    return ($cardType -eq "chengdao" -and (($kind -eq "order_beast") -or ($kind -eq "chaos_beast")))
}

$cards = Read-Json "data\cards\cards_v0.json"
$cardsById = @{}
foreach ($card in $cards) {
    $cardsById[$card.id] = $card
}

$daomasters = Read-Json "data\daomasters\daomasters_v0.json"
if ($daomasters.Count -ne 9) {
    throw "daomasters_v0.json should contain 9 daomasters, got $($daomasters.Count)."
}

$ids = @{}
$expectedDecks = @{
    "zaiheng_jun" = "starter_zaiheng"
    "zhiye_jun" = "starter_zhiye"
    "fuguan_seng" = "starter_fuguan"
}
$expectedPassives = @{
    "zaiheng_jun" = "hengjie"
    "zhiye_jun" = "liuxiao"
    "fuguan_seng" = "songgui"
}

foreach ($daomaster in $daomasters) {
    if ([string]::IsNullOrWhiteSpace($daomaster.id)) {
        throw "A daomaster is missing id."
    }
    if ($ids.ContainsKey($daomaster.id)) {
        throw "Duplicate daomaster id: $($daomaster.id)"
    }
    $ids[$daomaster.id] = $true
    foreach ($character in $daomaster.id.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($character) -eq [Globalization.UnicodeCategory]::Format) {
            throw "$($daomaster.id) contains an invisible format character."
        }
    }
    foreach ($field in @("title", "name", "group", "dao_tags", "role")) {
        if ($null -eq $daomaster.$field -or [string]::IsNullOrWhiteSpace([string]$daomaster.$field)) {
            throw "$($daomaster.id) missing required field: $field"
        }
    }
    if ($daomaster.unlocked.GetType().Name -ne "Boolean") {
        throw "$($daomaster.id) unlocked must be boolean."
    }
    if ($daomaster.unlocked) {
        if (-not $expectedDecks.ContainsKey($daomaster.id)) {
            throw "$($daomaster.id) is unlocked unexpectedly."
        }
        if ($daomaster.starter_deck_id -ne $expectedDecks[$daomaster.id]) {
            throw "$($daomaster.id) starter_deck_id should be $($expectedDecks[$daomaster.id]), got $($daomaster.starter_deck_id)."
        }
        if ($daomaster.passive_id -ne $expectedPassives[$daomaster.id]) {
            throw "$($daomaster.id) passive_id should be $($expectedPassives[$daomaster.id]), got $($daomaster.passive_id)."
        }
    } elseif ([string]::IsNullOrWhiteSpace($daomaster.lock_reason)) {
        throw "$($daomaster.id) is locked but missing lock_reason."
    }
}

$deckSignatures = @{}
foreach ($deckId in $expectedDecks.Values) {
    $deck = Read-Json "data\decks\pve\$deckId.json"
    if ($deck.cards.Count -ne 12) {
        throw "$deckId should contain 12 cards, got $($deck.cards.Count)."
    }
    $uniqueCards = @{}
    $counts = @{}
    foreach ($cardId in $deck.cards) {
        if (-not $cardsById.ContainsKey($cardId)) {
            throw "$deckId references missing card id: $cardId"
        }
        $uniqueCards[$cardId] = $true
        if (-not $counts.ContainsKey($cardId)) {
            $counts[$cardId] = 0
        }
        $counts[$cardId] += 1
        if ($cardsById[$cardId].type -eq "character") {
            throw "$deckId contains character card: $cardId"
        }
    }
    if ($uniqueCards.Count -lt 6) {
        throw "$deckId should contain at least 6 unique card ids, got $($uniqueCards.Count)."
    }
    foreach ($cardId in $counts.Keys) {
        if ($counts[$cardId] -gt 3) {
            Write-Warning "$deckId contains $cardId $($counts[$cardId]) times; suggested maximum is 3."
        }
    }
    $deckSignatures[$deckId] = (($deck.cards | Sort-Object) -join "|")
    $formationCount = 0
    $retainCount = 0
    $beastCount = 0
    foreach ($cardId in $deck.cards) {
        $card = $cardsById[$cardId]
        if (Is-FormationDirection $card) {
            $formationCount += 1
        }
        if (Has-Keyword $card @($KeywordNingmeng, $KeywordRetain)) {
            $retainCount += 1
        }
        if (Is-ChengdaoBeast $card) {
            $beastCount += 1
        }
    }
    if ($deckId -eq "starter_zaiheng" -and $formationCount -lt 4) {
        throw "starter_zaiheng should contain at least 4 formation-direction cards, got $formationCount."
    }
    if ($deckId -eq "starter_zhiye" -and $retainCount -lt 3) {
        Write-Warning "starter_zhiye should contain at least 3 retain cards, got $retainCount."
    }
    if ($deckId -eq "starter_fuguan" -and $beastCount -lt 3) {
        throw "starter_fuguan should contain at least 3 chengdao beast cards, got $beastCount."
    }
    Write-Output "Deck OK: $deckId ($($deck.cards.Count) cards)"
}

if (($deckSignatures["starter_zaiheng"] -eq $deckSignatures["starter_zhiye"]) -or
    ($deckSignatures["starter_zaiheng"] -eq $deckSignatures["starter_fuguan"]) -or
    ($deckSignatures["starter_zhiye"] -eq $deckSignatures["starter_fuguan"])) {
    throw "PVE starter decks should not be identical."
}

Write-Output "Daomaster data OK: 9 daomasters, unlocked = zaiheng_jun / zhiye_jun / fuguan_seng"
