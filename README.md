# SweedJesus Unit Frames

## Notes

### RosterLib

-   Unit table format:
    -   Keys in order of `RosterLib_UnitChanged` arguments
    -   Prepend all keys with `old` for old data

Key | Description
-- | --
`unitid` | Unit ID meta-type
`name` | Unit name
`class` | Unit class token
`subgroup` | Group in raid or 1 if in party
`rank` | 0 = member, 1 = assist, 2 = leader

-   `RosterLib_RosterChanged`

    Called once whenever the roster changes. Passes a table of all unit data
    changed.

-   `RosterLib_UnitChanged`
    
    Called for every unit that changes. Passes a series of 10 arguments for
    unit data that has changed. Instead of using this event use `RosterChanged`
    as it contains a single table of all units changed instead of series of
    arguments which is generally more useful.
