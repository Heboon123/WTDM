options gen2
options no_unused_block_arguments = false
options no_unused_function_arguments = false
options indenting = 4
options strict_smart_pointers = true

module faker shared private



require daslib/regex_boost
require daslib/random
require daslib/static_let
require daslib/strings
require daslib/defer
require math
require daslib/math_bits

struct MonthNameAndDay {
    name : string
    days : int
}

var private g_months <- [MonthNameAndDay(
    name="January", days=31), MonthNameAndDay(
    name="February", days=28), MonthNameAndDay(
    name="March", days=31), MonthNameAndDay(
    name="April", days=30), MonthNameAndDay(
    name="May", days=31), MonthNameAndDay(
    name="June", days=30), MonthNameAndDay(
    name="July", days=31), MonthNameAndDay(
    name="August", days=31), MonthNameAndDay(
    name="September", days=30), MonthNameAndDay(
    name="October", days=31), MonthNameAndDay(
    name="November", days=30), MonthNameAndDay(
    name="December", days=31
)];

var private g_days <- fixed_array<string>(
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday"
);

struct public Faker {
    
    min_year : uint = 1980u                     
    total_years : uint = (2022u - 1980u)        
    rnd : iterator<uint> <- each_random_uint()  
    max_long_string : uint = 4096u              
}

def public Faker(var rng : iterator<uint>) {
    return <-  Faker(rnd <- rng)
}

var private re_positive_int <- %regex~[0-9][0-9]*%%
var private re_int <- %regex~[\+\-]?[0-9][0-9]*%%
var private re_uint <- %regex~[0-9][0-9]*%%
var private re_hex <- %regex~[0-9a-zA-Z][0-9a-zA-Z]*%%
var private re_string <- %regex~.*%%
var private re_file_name <- %regex~[0-9a-zA-Z_\.]+%%
var private re_float <- %regex~[\+\-]?[0-9][0-9]*(\.[0-9]*)?%%
var re_number <- %regex~(zero|one|two|three|four|five|six|seven|eight|nine|ten)%%

def public long_string(var faker : Faker) : string {
    
    var len = 0u
    faker.rnd |> next(len)
    len %= faker.max_long_string
    var inscope arr : array<uint8>
    arr |> reserve(int(len))
    for (t in urange(len)) {
        var Ch = 0u
        faker.rnd |> next(Ch)
        arr |> push(uint8(Ch))
    }
    return string(arr)
}

def public any_string(var faker : Faker) : string {
    
    return re_gen(re_string, faker.rnd)
}

def public any_file_name(var faker : Faker) : string {
    
    return re_gen(re_file_name, faker.rnd)
}

def public random_int(var faker : Faker) : int {
    
    var i = 0u
    faker.rnd |> next(i)
    return int(i)
}

def public random_uint(var faker : Faker) : uint {
    
    var i = 0u
    faker.rnd |> next(i)
    return i
}

def public random_int8(var faker : Faker) : int8 {
    
    var i = 0u
    faker.rnd |> next(i)
    return int8(i)
}

def public random_uint8(var faker : Faker) : uint8 {
    
    var i = 0u
    faker.rnd |> next(i)
    return uint8(i)
}

def public random_int16(var faker : Faker) : int16 {
    
    var i = 0u
    faker.rnd |> next(i)
    return int16(i)
}

def public random_uint16(var faker : Faker) : uint16 {
    
    var i = 0u
    faker.rnd |> next(i)
    return uint16(i)
}

def public random_float(var faker : Faker) : float {
    
    var i = 0u
    faker.rnd |> next(i)
    return uint_bits_to_float(i)
}

def public random_int2(var faker : Faker) : int2 {
    
    return int2(faker |> random_int, faker |> random_int)
}

def public random_range(var faker : Faker) : range {
    
    return range(faker |> random_int, faker |> random_int)
}

def public random_range64(var faker : Faker) : range64 {
    
    return range64(faker |> random_int64, faker |> random_int64)
}

def public random_int3(var faker : Faker) : int3 {
    
    return int3(faker |> random_int, faker |> random_int, faker |> random_int)
}

def public random_int4(var faker : Faker) : int4 {
    
    return int4(faker |> random_int, faker |> random_int, faker |> random_int, faker |> random_int)
}

def public random_uint2(var faker : Faker) : uint2 {
    
    return uint2(faker |> random_uint, faker |> random_uint)
}

def public random_urange(var faker : Faker) : urange {
    
    return urange(faker |> random_uint, faker |> random_uint)
}

def public random_urange64(var faker : Faker) : urange64 {
    
    return urange64(faker |> random_uint64, faker |> random_uint64)
}

def public random_uint3(var faker : Faker) : uint3 {
    
    return uint3(faker |> random_uint, faker |> random_uint, faker |> random_uint)
}

def public random_uint4(var faker : Faker) : uint4 {
    
    return uint4(faker |> random_uint, faker |> random_uint, faker |> random_uint, faker |> random_uint)
}

def public random_float2(var faker : Faker) : float2 {
    
    return float2(faker |> random_float, faker |> random_float)
}

def public random_float3(var faker : Faker) : float3 {
    
    return float3(faker |> random_float, faker |> random_float, faker |> random_float)
}

def public random_float4(var faker : Faker) : float4 {
    
    return float4(faker |> random_float, faker |> random_float, faker |> random_float, faker |> random_float)
}

def public random_float3x3(var faker : Faker) : float3x3 {
    
    var m : float3x3
    m[0] = faker |> random_float3
    m[1] = faker |> random_float3
    m[2] = faker |> random_float3
    return m
}

def public random_float3x4(var faker : Faker) : float3x4 {
    
    var m : float3x4
    m[0] = faker |> random_float3
    m[1] = faker |> random_float3
    m[2] = faker |> random_float3
    m[3] = faker |> random_float3
    return m
}

def public random_float4x4(var faker : Faker) : float4x4 {
    
    var m : float4x4
    m[0] = faker |> random_float4
    m[1] = faker |> random_float4
    m[2] = faker |> random_float4
    m[3] = faker |> random_float4
    return m
}

variant BitRepresentation64 { 
    ui2 : uint[2]
    d   : double
    i64 : int64
    u64 : uint64
}

def public random_int64(var faker : Faker) : int64 {
    
    var b =  BitRepresentation64(ui2 = fixed_array<uint>(faker |> random_uint, faker |> random_uint))
    return unsafe(b.i64)
}

def public random_uint64(var faker : Faker) : uint64 {
    
    var b =  BitRepresentation64(ui2 = fixed_array<uint>(faker |> random_uint, faker |> random_uint))
    return unsafe(b.u64)
}

def public random_double(var faker : Faker) : double {
    
    var b =  BitRepresentation64(ui2 = fixed_array<uint>(faker |> random_uint, faker |> random_uint))
    return unsafe(b.d)
}

def public any_set(var faker : Faker) : uint[8] {
    
    var ch : uint[8]
    for (c in ch) {
        faker.rnd |> next(c)
    }
    return ch
}

def public any_char(var faker : Faker) : int {
    
    var ch = 0u
    faker.rnd |> next(ch)
    return int((ch % 255u) + 1u)
}

def public number(var faker : Faker) : string {
    
    return re_gen(re_number, faker.rnd)
}

def public positive_int(var faker : Faker) : string {
    
    return re_gen(re_positive_int, faker.rnd)
}

def public any_int(var faker : Faker) : string {
    
    return re_gen(re_int, faker.rnd)
}

def public any_hex(var faker : Faker) : string {
    
    return re_gen(re_hex, faker.rnd)
}

def public any_float(var faker : Faker) : string {
    
    return re_gen(re_float, faker.rnd)
}

def public any_uint(var faker : Faker) : string {
    
    return re_gen(re_uint, faker.rnd)
}

def public month(var faker : Faker) {
    
    var month = 0u
    faker.rnd |> next(month)
    month = month % 12u
    return g_months[month].name
}

def public day(var faker : Faker) {
    
    var day = 0u
    faker.rnd |> next(day)
    day = day % 7u
    return g_days[day]
}

def public is_leap_year(year : uint) {
    
    return (year % 4u == 0u) && (year % 100u != 0u || year % 400u == 0u)
}

def public week_day(year, month, day : uint) {
    
    return week_day(int(year), int(month), int(day))
}

def public week_day(year, month, day : int) {
    
    static_let <| $() {
        let offset <- [ 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    }
    var afterFeb = 1
    if (month > 2) {
        afterFeb = 0
    }
    let aux = year - 1700 - afterFeb
    
    var dayOfWeek  = 5
    
    dayOfWeek += (aux + afterFeb) * 365
    
    dayOfWeek += aux / 4 - aux / 100 + (aux + 100) / 400
    
    dayOfWeek += offset[month] + (day - 1)
    dayOfWeek %= 7
    return dayOfWeek
}

def public date(var faker : Faker) {
    
    var month = 0u
    var day = 0u
    var year = 0u
    faker.rnd |> next(month)
    faker.rnd |> next(year)
    faker.rnd |> next(day)
    month = month % 12u
    year = faker.min_year + (year % faker.total_years)
    var max_days = uint(g_months[month].days)
    if (is_leap_year(year) && month == 1u) {
        max_days = 29u
    }
    day = 1u + (day % max_days)
    let dow = week_day(year, month, day)
    return "{g_days[dow]}, {g_months[month].name} {int(day)}, {int(year)}"
}
