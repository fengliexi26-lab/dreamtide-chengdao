$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

$Errors = New-Object System.Collections.Generic.List[string]
$Warnings = New-Object System.Collections.Generic.List[string]

$AllowedCardTypes = @("daofa", "chengdao")
$AllowedOwnerScopes = @("universal", "shared", "exclusive")
$AllowedEffectTypes = @("deal_damage", "gain_formation", "draw", "gain_daoxi", "gain_reflux", "reduce_reflux", "summon")
$KeywordRetainDream = [string]::Concat([char]0x51DD, [char]0x68A6)
$KeywordExhaust = [string]::Concat([char]0x6D88, [char]0x8017)
$RequiredFields = @(
    "id",
    "name",
    "card_type",
    "subtype",
    "owner_scope",
    "owner_ids",
    "pool_tags",
    "rarity",
    "cost",
    "target_type",
    "effects",
    "keywords",
    "dao_tags",
    "side",
    "starter_allowed",
    "reward_allowed",
    "implementation_status",
    "implementation_phase",
    "effect_text",
    "flavor_text"
)

function Add-Error([string]$Message) {
    $script:Errors.Add($Message) | Out-Null
}

function Add-Warning([string]$Message) {
    $script:Warnings.Add($Message) | Out-Null
}

function Read-Json($RelativePath) {
    $path = Join-Path $ProjectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing file: $RelativePath"
    }
    $value = Get-Content -LiteralPath $path -Encoding UTF8 | ConvertFrom-Json
    if ($value -is [System.Array]) {
        foreach ($item in $value) {
            Write-Output $item
        }
    } else {
        Write-Output $value
    }
}

function Is-ArrayValue($Value) {
    return ($null -ne $Value -and $Value -is [System.Array])
}

function Has-Keyword($Card, [string]$Keyword) {
    foreach ($keywordValue in @($Card.keywords)) {
        if ([string]$keywordValue -eq $Keyword) {
            return $true
        }
    }
    return $false
}

function Get-EffectsOfType($Card, [string]$TypeName) {
    $result = @()
    foreach ($effect in @($Card.effects)) {
        if ([string]$effect.type -eq $TypeName) {
            $result += $effect
        }
    }
    return $result
}

function Has-DirectDamage($Card) {
    return (@(Get-EffectsOfType $Card "deal_damage").Count -gt 0)
}

function Is-SurvivalCard($Card) {
    if (@(Get-EffectsOfType $Card "gain_formation").Count -gt 0) {
        return $true
    }
    if ([string]$Card.card_type -eq "chengdao") {
        return $true
    }
    if (Has-Keyword $Card $script:KeywordRetainDream) {
        return $true
    }
    return $false
}

function Is-Chengdao($Card) {
    return ([string]$Card.card_type -eq "chengdao")
}

function Is-Exhaust($Card) {
    return (Has-Keyword $Card $script:KeywordExhaust)
}

function Get-CardScopeForDeck($Card, [string]$DaomasterId) {
    $scope = [string]$Card.owner_scope
    if ($scope -eq "exclusive") {
        if (@($Card.owner_ids) -contains $DaomasterId) {
            return "exclusive"
        }
        return "invalid_exclusive"
    }
    if ($scope -eq "shared") {
        if (@($Card.owner_ids) -contains $DaomasterId) {
            return "shared"
        }
        return "invalid_shared"
    }
    return $scope
}

Write-Output "PVE Card V1 validation started."

$cards = $null
try {
    $cards = @(Read-Json "data\cards\pve\cards_pve_v1.json")
    Write-Output "PASS cards_pve_v1.json parsed."
} catch {
    Write-Output "ERROR cards_pve_v1.json parse failed: $($_.Exception.Message)"
    exit 1
}

if ($cards.Count -eq 39) { Write-Output "PASS card count = 39." } else { Add-Error "cards_pve_v1.json should contain 39 cards, got $($cards.Count)." }

$ids = @{}
$cardsById = @{}
$summonIds = @{}
$idPattern = "^[a-z0-9_]+$"

foreach ($card in $cards) {
    $cardId = [string]$card.id
    if ([string]::IsNullOrWhiteSpace($cardId)) {
        Add-Error "A card is missing id."
        continue
    }
    if ($ids.ContainsKey($cardId)) {
        Add-Error "Duplicate card id: $cardId"
    }
    $ids[$cardId] = $true
    $cardsById[$cardId] = $card

    if ($cardId -notmatch $idPattern) {
        Add-Error "$cardId contains invalid characters. Use lowercase letters, digits, and underscores only."
    }
    foreach ($character in $cardId.ToCharArray()) {
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($character) -eq [Globalization.UnicodeCategory]::Format) {
            Add-Error "$cardId contains an invisible Unicode format character."
        }
    }

    foreach ($field in $RequiredFields) {
        if (-not ($card.PSObject.Properties.Name -contains $field)) {
            Add-Error "$cardId missing required field: $field"
        }
    }

    foreach ($arrayField in @("effects", "keywords", "owner_ids", "pool_tags", "dao_tags")) {
        if (-not (Is-ArrayValue $card.$arrayField)) {
            Add-Error "$cardId field $arrayField must be an array."
        }
    }

    if (-not ($AllowedCardTypes -contains [string]$card.card_type)) {
        Add-Error "$cardId card_type must be daofa or chengdao, got $($card.card_type)."
    }
    if (-not ($AllowedOwnerScopes -contains [string]$card.owner_scope)) {
        Add-Error "$cardId owner_scope must be universal/shared/exclusive, got $($card.owner_scope)."
    }
    if ($null -eq $card.cost -or $card.cost -isnot [int] -or [int]$card.cost -lt 0) {
        Add-Error "$cardId cost must be a non-negative integer."
    }
    if ($card.starter_allowed -isnot [bool]) {
        Add-Error "$cardId starter_allowed must be boolean."
    }
    if ($card.reward_allowed -isnot [bool]) {
        Add-Error "$cardId reward_allowed must be boolean."
    }
    if ([string]$card.implementation_phase -eq "phase_1_base") {
        foreach ($effect in @($card.effects)) {
            if (-not ($AllowedEffectTypes -contains [string]$effect.type)) {
                Add-Error "$cardId uses unsupported phase_1_base effect type: $($effect.type)."
            }
        }
    }
    if ([string]$card.rarity -eq "basic" -and [bool]$card.reward_allowed) {
        Add-Error "$cardId is basic but reward_allowed is true."
    }
    if ([int]$card.cost -eq 0 -and @(Get-EffectsOfType $card "draw").Count -gt 0 -and -not (Has-Keyword $card $script:KeywordExhaust)) {
        Add-Error "$cardId is 0-cost draw but does not have exhaust keyword."
    }

    if ([string]$card.card_type -eq "chengdao") {
        if (-not ($card.PSObject.Properties.Name -contains "summon_data")) {
            Add-Error "$cardId is chengdao but missing summon_data."
        } else {
            $data = $card.summon_data
            foreach ($field in @("summon_id", "attack", "life", "side", "dao_tags", "chengdao_kind", "death_destination", "is_special")) {
                if (-not ($data.PSObject.Properties.Name -contains $field)) {
                    Add-Error "$cardId summon_data missing $field."
                }
            }
            if ($data.attack -isnot [int] -or [int]$data.attack -lt 0) {
                Add-Error "$cardId summon attack must be a non-negative integer."
            }
            if ($data.life -isnot [int] -or [int]$data.life -le 0) {
                Add-Error "$cardId summon life must be a positive integer."
            }
            if (-not (Is-ArrayValue $data.dao_tags)) {
                Add-Error "$cardId summon_data.dao_tags must be an array."
            }
            if ([string]$data.death_destination -notin @("discard", "exhaust")) {
                Add-Error "$cardId death_destination must be discard or exhaust."
            }
            if ($data.is_special -isnot [bool]) {
                Add-Error "$cardId is_special must be boolean."
            }
            if ([string]$data.death_destination -eq "exhaust" -and -not [bool]$data.is_special) {
                Add-Error "$cardId has death_destination exhaust but is_special is false."
            }
            $summonId = [string]$data.summon_id
            if ([string]::IsNullOrWhiteSpace($summonId)) {
                Add-Error "$cardId summon_id is empty."
            } elseif ($summonIds.ContainsKey($summonId)) {
                Add-Error "Duplicate summon_id: $summonId"
            } else {
                $summonIds[$summonId] = $cardId
            }
        }
    }
}

$universalCount = @($cards | Where-Object { $_.owner_scope -eq "universal" }).Count
$sharedCount = @($cards | Where-Object { $_.owner_scope -eq "shared" }).Count
$zaihengExclusiveCount = @($cards | Where-Object { $_.owner_scope -eq "exclusive" -and @($_.owner_ids) -contains "zaiheng_jun" }).Count
$zhiyeExclusiveCount = @($cards | Where-Object { $_.owner_scope -eq "exclusive" -and @($_.owner_ids) -contains "zhiye_jun" }).Count
$fuguanExclusiveCount = @($cards | Where-Object { $_.owner_scope -eq "exclusive" -and @($_.owner_ids) -contains "fuguan_seng" }).Count

if ($universalCount -eq 6) { Write-Output "PASS universal count = 6." } else { Add-Error "Universal count should be 6, got $universalCount." }
if ($sharedCount -eq 9) { Write-Output "PASS shared count = 9." } else { Add-Error "Shared count should be 9, got $sharedCount." }
if ($zaihengExclusiveCount -eq 8) { Write-Output "PASS zaiheng exclusive count = 8." } else { Add-Error "Zaiheng exclusive count should be 8, got $zaihengExclusiveCount." }
if ($zhiyeExclusiveCount -eq 8) { Write-Output "PASS zhiye exclusive count = 8." } else { Add-Error "Zhiye exclusive count should be 8, got $zhiyeExclusiveCount." }
if ($fuguanExclusiveCount -eq 8) { Write-Output "PASS fuguan exclusive count = 8." } else { Add-Error "Fuguan exclusive count should be 8, got $fuguanExclusiveCount." }

$deckSpecs = @(
    @{ Path = "data\decks\pve_v1\starter_zaiheng_v1.json"; Daomaster = "zaiheng_jun"; Name = "starter_zaiheng_v1" },
    @{ Path = "data\decks\pve_v1\starter_zhiye_v1.json"; Daomaster = "zhiye_jun"; Name = "starter_zhiye_v1" },
    @{ Path = "data\decks\pve_v1\starter_fuguan_v1.json"; Daomaster = "fuguan_seng"; Name = "starter_fuguan_v1" }
)

foreach ($deckSpec in $deckSpecs) {
    $deck = $null
    try {
        $deck = Read-Json $deckSpec.Path
        Write-Output "PASS $($deckSpec.Name) parsed."
    } catch {
        Add-Error "$($deckSpec.Name) parse failed: $($_.Exception.Message)"
        continue
    }

    $cardIds = @($deck.cards)
    if ($cardIds.Count -eq 12) { Write-Output "PASS $($deckSpec.Name) has 12 cards." } else { Add-Error "$($deckSpec.Name) should contain 12 cards, got $($cardIds.Count)." }

    $counts = @{}
    $scopeCounts = @{ universal = 0; shared = 0; exclusive = 0 }
    $unique = @{}
    $damageCount = 0
    $survivalCount = 0
    $retainCount = 0
    $retainIds = @{}
    $chengdaoIds = @{}
    $exhaustCount = 0

    foreach ($cardId in $cardIds) {
        if (-not $counts.ContainsKey($cardId)) { $counts[$cardId] = 0 }
        $counts[$cardId] += 1
        $unique[$cardId] = $true

        if (-not $cardsById.ContainsKey($cardId)) {
            Add-Error "$($deckSpec.Name) references missing card id: $cardId"
            continue
        }

        $card = $cardsById[$cardId]
        $scope = Get-CardScopeForDeck $card $deckSpec.Daomaster
        if ($scope -eq "invalid_exclusive" -or $scope -eq "invalid_shared") {
            Add-Error "$($deckSpec.Name) contains incompatible $($card.owner_scope) card: $cardId"
        } elseif ($scopeCounts.ContainsKey($scope)) {
            $scopeCounts[$scope] += 1
        }

        if (Has-DirectDamage $card) { $damageCount += 1 }
        if (Is-SurvivalCard $card) { $survivalCount += 1 }
        if (Has-Keyword $card $script:KeywordRetainDream) {
            $retainCount += 1
            $retainIds[$cardId] = $true
        }
        if (Is-Chengdao $card) {
            $chengdaoIds[$cardId] = $true
        }
        if (Is-Exhaust $card) { $exhaustCount += 1 }
        if ([string]$card.implementation_phase -ne "phase_1_base") {
            Add-Error "$($deckSpec.Name) contains non-phase_1_base card: $cardId"
        }
    }

    if ($scopeCounts.exclusive -ne 7 -or $scopeCounts.shared -ne 3 -or $scopeCounts.universal -ne 2) {
        Add-Error "$($deckSpec.Name) ratio should be exclusive/shared/universal = 7/3/2, got $($scopeCounts.exclusive)/$($scopeCounts.shared)/$($scopeCounts.universal)."
    } else {
        Write-Output "PASS $($deckSpec.Name) ratio = 7/3/2."
    }

    if ($unique.Count -lt 8) { Add-Error "$($deckSpec.Name) should contain at least 8 unique ids, got $($unique.Count)." }
    foreach ($cardId in $counts.Keys) {
        if ($counts[$cardId] -gt 2) {
            Add-Error "$($deckSpec.Name) contains $cardId $($counts[$cardId]) times; maximum is 2."
        }
    }
    if ($damageCount -lt 3) { Add-Error "$($deckSpec.Name) should contain at least 3 direct damage instances, got $damageCount." }
    if ($survivalCount -lt 3) { Add-Error "$($deckSpec.Name) should contain at least 3 defense/survival instances, got $survivalCount." }
    if ($chengdaoIds.Count -lt 1 -or $chengdaoIds.Count -gt 3) { Add-Warning "$($deckSpec.Name) has $($chengdaoIds.Count) different chengdao ids; expected roughly 1-2 except fuguan." }

    if ($deckSpec.Daomaster -eq "zhiye_jun") {
        if ($retainCount -lt 4 -or $retainCount -gt 5) {
            Add-Error "starter_zhiye_v1 should contain 4-5 retain-dream instances, got $retainCount."
        }
        if ($retainIds.Count -lt 3) {
            Add-Error "starter_zhiye_v1 should contain at least 3 different retain-dream ids, got $($retainIds.Count)."
        }
    }
    if ($deckSpec.Daomaster -eq "fuguan_seng") {
        if ($chengdaoIds.Count -lt 3) {
            Add-Error "starter_fuguan_v1 should contain at least 3 different chengdao ids, got $($chengdaoIds.Count)."
        }
        if ($exhaustCount -lt 2) {
            Add-Error "starter_fuguan_v1 should contain at least 2 exhaust instances, got $exhaustCount."
        }
    }
}

if ($Warnings.Count -gt 0) {
    foreach ($warning in $Warnings) {
        Write-Output "WARNING $warning"
    }
}

if ($Errors.Count -gt 0) {
    foreach ($errorMessage in $Errors) {
        Write-Output "ERROR $errorMessage"
    }
    Write-Output "PVE Card V1 validation failed with $($Errors.Count) error(s)."
    exit 1
}

Write-Output "PASS PVE Card V1 validation completed without errors."
exit 0
