# three.js Animation — Cited Reference (three@0.186.1 / r186)

Verification basis: every API signature below was read from the **r186 source on GitHub**
(`raw.githubusercontent.com/mrdoob/three.js/r186/...`), not from docs prose or LLM recall.
Migration claims are quoted from the official
[Migration Guide](https://github.com/mrdoob/three.js/wiki/Migration-Guide).
Anything not verified is marked **UNVERIFIED**.

---

## 0. Things that DO NOT EXIST in r186 (do not generate them)

| Claimed API | Reality in r186 |
|---|---|
| `AnimationUtils.arraySlice()` | **Removed in r157.** Guide 156→157: "`AnimationUtils.arraySlice()` has been removed. Internal code uses the native `TypedArray.slice()` method instead." Use `typedArray.slice()`. |
| `AnimationUtils.toHalfFloat()` | Not in `AnimationUtils`. Half-float conversion is `DataUtils.toHalfFloat( val )` in [`src/extras/DataUtils.js`](https://github.com/mrdoob/three.js/blob/r186/src/extras/DataUtils.js) (exports `toHalfFloat`, `fromHalfFloat`, `DataUtils`). |
| `AnimationUtils.lerp()` | Does not exist. Full export list of r186 `AnimationUtils.js`: `convertArray`, `isTypedArray`, `hasTangents`, `getKeyframeOrder`, `sortedArray`, `flattenJSON`, `subclip`, `makeClipAdditive`, `AnimationUtils`. |
| `AnimationUtils.normalizeMorphTargets` / any `normalize*` morph helper | No such method. Morph weight normalization is `SkinnedMesh.normalizeSkinWeights()` (normalizes `geometry.attributes.skinWeight`, not morph influences). |
| `AnimationClip.createFromMorphTargetSequence` (lowercase c) | **Capital C**: `AnimationClip.CreateFromMorphTargetSequence(...)` and `AnimationClip.CreateClipsFromMorphTargetSequences(...)`. |
| `InterpolantLinear` / `InterpolantDiscrete` / `InterpolantSmoothStep` / `InterpolantCubicSpline` classes | No such classes. `InterpolateLinear`/`InterpolateDiscrete`/`InterpolateSmooth`/`InterpolateBezier` are **numeric constants** (see §1.4). The interpolant classes are `LinearInterpolant`, `DiscreteInterpolant`, `CubicInterpolant`, `BezierInterpolant`, `QuaternionLinearInterpolant` (all in `src/math/interpolants/`). |
| `Interpolations` = animation interpolation module | **Wrong.** [`Interpolations`](https://threejs.org/docs/pages/module-Interpolations.html) is `src/extras/core/Interpolations.js` and contains only `CatmullRom`, `CubicBezier`, `QuadraticBezier` — curve helper formulas, unrelated to keyframe tracks. |
| `GLTFCubicSplineInterpolant` in core | It lives inside [`examples/jsm/loaders/GLTFLoader.js`](https://github.com/mrdoob/three.js/blob/r186/examples/jsm/loaders/GLTFLoader.js), not `src/`. Not exported. |
| `MMDLoader`, `MMDFLoader`, `VMDLoader` in `three/addons/loaders/` | **Gone.** The r186 `examples/jsm/loaders/` directory (56 entries, verified via GitHub contents API at ref `r186`) contains no MMD loader. MMD modules were deprecated at r170: "Please migrate to `takahirox/three-mmd-loader` until `r172`." |
| `Bone.getWorldPosition()` / `Bone.getWorldQuaternion()` as Bone methods | They are **inherited from `Object3D`** — `Bone` (`src/objects/Bone.js`, 612 bytes total) adds only `isBone` and `type`. Calling them is valid JS via inheritance; do not claim they live on `Bone`. |
| `AnimationGraph`, `GPUParticleSystem`, `NodeMaterial.addNode()`, `AnimationMixer.clipGraph()` | Not present anywhere in r186. Never generate. |

---

## 1. Canonical subsystem inventory (verified signatures)

All core animation classes are exported from `three` (no `three/addons/` path). Import: `import { AnimationMixer, ... } from 'three';`

### 1.1 `AnimationMixer` — [`src/animation/AnimationMixer.js`](https://github.com/mrdoob/three.js/blob/r186/src/animation/AnimationMixer.js)

```js
new THREE.AnimationMixer( root : Object3D )   // extends EventDispatcher
```

| Member | Signature |
|---|---|
| `time` | `number`, starts `0`, global mixer time in seconds |
| `timeScale` | `number`, default `1.0`. Setting `0` then back to `1` is the documented way to pause/unpause all actions |
| `.clipAction( clip : AnimationClip \| string, optionalRoot : Object3D, blendMode )` | Returns the action, **creating it if absent**; repeated calls with same clip+root return the same action |
| `.existingAction( clip, optionalRoot )` | Same lookup, returns `null` if none |
| `.getRoot() : Object3D` | |
| `.setTime( time : number ) : AnimationMixer` | See §3 |
| `.update( deltaTime : number ) : AnimationMixer` | See §3 |
| `.stopAllAction() : AnimationMixer` | |
| `.uncacheAction( clip, optionalRoot )` | Requires `action.stop()` first |
| `.uncacheClip( clip )` | Requires `action.stop()` for all related actions first |
| `.uncacheRoot( root )` | Requires `stop()` on all actions, or `stopAllAction()` for a single-root mixer |

**No API change to `AnimationMixer` in r177–r186.** The Migration Guide sections for 177→178 through 185→186 contain **zero** entries touching `AnimationMixer`, `AnimationAction`, `AnimationClip`, `KeyframeTrack`, `PropertyBinding`, `PropertyMixer`, or `Skeleton`. The only animation-adjacent changes in the window are itemized in §2.

### 1.2 `AnimationAction` — [`src/animation/AnimationAction.js`](https://github.com/mrdoob/three.js/blob/r186/src/animation/AnimationAction.js)

Constructed only by `mixer.clipAction()`; constructor signature
`( mixer, clip, localRoot = null, blendMode = clip.blendMode )`.

Full method list verified in r186 source:
`play()`, `stop()`, `reset()`, `isRunning()`, `isScheduled()`, `startAt( time )`,
`setLoop( mode, repetitions )`, `setEffectiveWeight( w )`, `getEffectiveWeight()`,
`fadeIn( duration )`, `fadeOut( duration )`, `crossFadeFrom( fadeOutAction, duration )`,
`crossFadeTo( fadeInAction, duration )`, `stopFading()`,
`setEffectiveTimeScale( s )`, `getEffectiveTimeScale()`, `setDuration( d )`,
`syncWith( action )`, `halt( duration )`, `warp( s, t, u, v )`, `stopWarping()`,
`getMixer()`, `getClip()`, `getRoot()`.

Writable properties: `enabled`, `paused`, `weight`, `timeScale`, `time`, `repetitions`,
`clampWhenFinished`, `loop`, `blendMode`. Loop modes are constants
`LoopRepeat` / `LoopOnce` / `LoopPingPong` from `constants.js`.

### 1.3 `AnimationClip` — [`src/animation/AnimationClip.js`](https://github.com/mrdoob/three.js/blob/r186/src/animation/AnimationClip.js)

```js
new THREE.AnimationClip( name = '', duration = -1, tracks = [], blendMode = NormalAnimationBlendMode )
```

| Member | Signature / note |
|---|---|
| `.tracks` | `Array<KeyframeTrack>` |
| `.duration` | seconds; `-1` triggers `resetDuration()` (max of all `track.times[last]`) |
| `.blendMode` | `NormalAnimationBlendMode` \| `AdditiveAnimationBlendMode` |
| `.userData` | JSON-serializable; **no functions** (they won't survive `clone()`) |
| `.resetDuration()` | Recompute from longest track |
| `.trim()` | Trims every track to `[0, duration]` |
| `.validate()` / `.optimize()` | `optimize()` drops redundant keys (does not run for `InterpolateSmooth`) |
| `.clone()` / `.toJSON()` | |
| `AnimationClip.parse( json )` | Static. **Note:** `json.fps` scales track times by `1/fps` |
| `AnimationClip.toJSON( clip )` | Static |
| **`AnimationClip.CreateFromMorphTargetSequence( name, morphTargetSequence, fps, noLoop )`** | **Capital C.** Emits `NumberKeyframeTrack`s named `'.morphTargetInfluences[' + target.name + ']'` and `.scale(1/fps)`. `fps` is **required**. |
| **`AnimationClip.CreateClipsFromMorphTargetSequences( morphTargets, fps, noLoop )`** | Capital C plural. Groups names by trailing digits (`/^([\w-]*?)([\d]+)$/`) |
| **`AnimationClip.findByName( objectOrClipArray, name )`** | lowercase `b`. Accepts an array **or** an Object3D/geometry with `.animations`. Returns `null` if absent — it does **not** throw |

### 1.4 Track classes — [`src/animation/KeyframeTrack.js`](https://github.com/mrdoob/three.js/blob/r186/src/animation/KeyframeTrack.js), `src/animation/tracks/*`

```js
new THREE.KeyframeTrack( name : string, times : Array, values : Array, interpolation )
// throws if name === undefined, or times is undefined/length 0
```

- `this.times = AnimationUtils.convertArray( times, this.TimeBufferType )` → **`Float32Array`**
- `this.values = AnimationUtils.convertArray( values, this.ValueBufferType )` → **`Float32Array`** (base class)
- `this.setInterpolation( interpolation || this.DefaultInterpolation )`

**`values.length` must equal `times.length * getValueSize()`.** `getValueSize()` is
literally `this.values.length / this.times.length` — there is no separate itemSize field,
so a mismatch silently produces a fractional stride. `validate()` reports
"Invalid value size in track." — but it is **opt-in**; the constructor does not validate.

Interpolation is the `interpolation` **constant**, not a class:

| Constant | r186 value | Factory → interpolant |
|---|---|---|
| `InterpolateDiscrete` | `2300` | `DiscreteInterpolant` (holds previous sample) |
| `InterpolateLinear` | `2301` (default) | `LinearInterpolant`; `QuaternionLinearInterpolant` for quaternion tracks |
| `InterpolateSmooth` | `2302` | `CubicInterpolant` (Catmull-Rom) |
| `InterpolateBezier` | `2303` | `BezierInterpolant`, requires `track.settings.inTangents/outTangents` |

*(values from [`src/constants.js`](https://github.com/mrdoob/three.js/blob/r186/src/constants.js))*

- `.setInterpolation( interpolation ) : KeyframeTrack` — returns `this`. On an unknown
  value it falls back to `DefaultInterpolation` and `warn()`s (does not throw), unless the
  default itself is broken.
- `.getInterpolation()` — returns the constant, or `undefined` for custom factory methods
  (this is exactly what the GLTF CUBICSPLINE path hits).
- `.shift( timeOffset )`, `.scale( timeScale )` (also scales tangent times),
  `.trim( startTime, endTime )`, `.validate()`, `.optimize()`, `.clone()`.
  `clone()` copies `createInterpolant` directly because the constructor arg isn't retained.

Subclasses (all in `src/animation/tracks/`):

| Class | `ValueTypeName` | Notes |
|---|---|---|
| `NumberKeyframeTrack` | `'number'` | `ValueBufferType` → `Float32Array` |
| `VectorKeyframeTrack` | `'vector'` | position/scale |
| `QuaternionKeyframeTrack` | `'quaternion'` | overrides `InterpolantFactoryMethodLinear` → SLERP. **`InterpolantFactoryMethodSmooth = undefined`** — setting `InterpolateSmooth` on a quaternion track falls back + warns |
| `ColorKeyframeTrack` | `'color'` | |
| `BooleanKeyframeTrack` | `'bool'` | `Array`, `InterpolateDiscrete` default |
| `StringKeyframeTrack` | `'string'` | `Array` |

Blend modes (same `constants.js`): `NormalAnimationBlendMode = 2500`,
`AdditiveAnimationBlendMode = 2501`.

### 1.5 `PropertyBinding` — [`src/animation/PropertyBinding.js`](https://github.com/mrdoob/three.js/blob/r186/src/animation/PropertyBinding.js)

Track-name grammar accepted by `PropertyBinding.parseTrackName()` (from the r186 JSDoc):

```
nodeName.property
nodeName.property[accessor]
nodeName.material.property[accessor]
uuid.property[accessor]
uuid.objectName[objectIndex].propertyName[propertyIndex]
parentName/nodeName.property
parentName/parentName/nodeName.property[index]
.bone[Armature.DEF_cog].position
scene:helium_balloon_model:helium_balloon_model.position
```

Reserved characters are `[ ] . : /`; they are stripped from node names.
`_supportedObjectNames = ['material', 'materials', 'bones', 'map']` — only these are
recognised as the `objectName` segment; anything else is folded into `nodeName`.
`PropertyBinding.sanitizeNodeName( name )` replaces whitespace with `_` and removes
reserved chars — use it when authoring track names from untrusted strings.

`PropertyBinding.findNode( root, nodeName )` resolution order, in order:
1. `nodeName` is `undefined` / `''` / `'.'` / `-1` / `root.name` / `root.uuid` → **root itself**
   (this is why `.position`, `.quaternion`, `.scale` — a leading dot — mean "the root")
2. `root.skeleton.getBoneByName( nodeName )` — **first** bone with that name
3. depth-first search of `root.children` matching `childNode.name === nodeName || childNode.uuid === nodeName` — **first** match wins

Members: `.path`, `.parsedPath`, `.node`, `.rootNode`, `.bind()`, `.unbind()`,
`PropertyBinding.create( root, path, parsedPath )` (returns a `Composite` when the root is
an `AnimationObjectGroup`).

Special-cased property routing in `bind()`:
- `material` → `Versioning.NeedsUpdate` is set on writes (so `material.opacity` works)
- any `Object3D` → `Versioning.MatrixWorldNeedsUpdate` is set on writes
- `.bones[Armature.bones[DEF_cog]]` → resolves bone name → index
- `.morphTargetInfluences[targetName]` → resolves via `targetObject.morphTargetDictionary`

### 1.6 `AnimationUtils` — full verified surface

| Method | Signature |
|---|---|
| `convertArray( array, type ) : TypedArray` | no-op if `array.constructor === type` |
| `isTypedArray( object ) : boolean` | |
| `hasTangents( settings ) : boolean` | true only if both `inTangents` and `outTangents` defined |
| `getKeyframeOrder( times ) : Array<number>` | sort permutation |
| `sortedArray( values, stride, order ) : Array<number>` | |
| `flattenJSON( jsonKeys, times, values, valuePropertyName )` | fills `times`/`values` from AOS keyframes |
| `subclip( sourceClip, name, startFrame, endFrame, fps = 30 ) : AnimationClip` | drops out-of-range keys, then shifts all tracks so the clip starts at `t = 0` |
| **`makeClipAdditive( targetClip, referenceFrame = 0, referenceClip = targetClip, fps = 30 ) : AnimationClip`** | see below |

`makeClipAdditive` internals worth knowing:
- `referenceTime = referenceFrame / fps` (`fps <= 0` is coerced to 30)
- matches target tracks to reference tracks **by `track.name` AND `track.ValueTypeName`**
- skips `ValueTypeName` of `'bool'` and `'string'` entirely
- for CUBICSPLINE tracks it offsets by `valueSize / 3` to skip the tangent entries
- if the reference frame is outside the track's key range it **clamps** to the first/last key;
  otherwise it **interpolates** the reference value
- for `quaternion` it conjugates the reference and does `multiplyQuaternionsFlat`
- finally sets `targetClip.blendMode = AdditiveAnimationBlendMode` and mutates in place

### 1.7 `PropertyMixer` (internal but explains the blending you see)

Buffer layout, per the r186 source comment:
`[ incoming | accu0 | accu1 | orig | addAccu | (work, quaternions only) ]`, `Float64Array`.
`_origIndex = 3`, `_addIndex = 4`, quaternion `_workIndex = 5`.

- `accumulate( accuIndex, weight )` — weighted blend into `accuN`; `_lerp` for numeric,
  `_slerp` for quaternion, `_select` for string/bool
- `accumulateAdditive( weight )` — `add := add + incoming * weight`; `_lerpAdditive` /
  `_slerpAdditive`
- `apply( accuIndex )` — mixes `orig * (1 - cumulativeWeight)` in when weight < 1, then the
  additive accumulator, then **only calls `binding.setValue()` if the accumulated buffer
  actually differs from the other accu buffer.** Writes are skipped when nothing changed.
- `saveOriginalState()` — called when an action is activated; seeds `orig`, both accus, and
  the additive identity.

### 1.8 `Skeleton` / `Bone` / `SkinnedMesh`

[`src/objects/Skeleton.js`](https://github.com/mrdoob/three.js/blob/r186/src/objects/Skeleton.js):

| Member | Note |
|---|---|
| `new THREE.Skeleton( bones = [], boneInverses = [] )` | `boneInverses.length === 0` → `init()` calls `calculateInverses()` |
| `.init()` | allocates `boneMatrices = new Float32Array( bones.length * 16 )`; warns + rebuilds inverses if lengths mismatch |
| **`.calculateInverses()`** | **Present and unchanged.** Resets `boneInverses` and fills `invert( bones[i].matrixWorld )` per bone. **Therefore it needs `matrixWorld` to be current → call it only after the skeleton is parented and world matrices are up to date** |
| `.pose()` | recovers bind-time world matrices from `boneInverses`, then decomposes back into `position`/`quaternion`/`scale` |
| `.update()` | flattens `matrixWorld * boneInverse[i]` into `boneMatrices`; flags `boneTexture.needsUpdate` |
| `.getBoneByName( name ) : Bone \| undefined` | **first** match |
| `.computeBoneTexture()` | builds the `DataTexture`; 1 matrix = 4 RGBA pixels |
| `.dispose()`, `.clone()`, `.fromJSON()`, `.toJSON()` | |

[`src/objects/SkinnedMesh.js`](https://github.com/mrdoob/three.js/blob/r186/src/objects/SkinnedMesh.js):

| Member | Note |
|---|---|
| `.bind( skeleton, bindMatrix )` | With **no** `bindMatrix`: calls `updateMatrixWorld(true)`, then `skeleton.calculateInverses()`, then uses `matrixWorld` as the bind matrix |
| `.pose()` | delegates to `skeleton.pose()` |
| `.normalizeSkinWeights()` | normalizes `skinWeight` buffer attribute; zeroes → `(1,0,0,0)` |
| `.bindMode` | `AttachedBindMode` (default) \| `DetachedBindMode` |
| `.bindMatrix`, `.bindMatrixInverse` | |
| `.computeBoundingBox()` / `.computeBoundingSphere()` | use `getVertexPosition()` → `applyBoneTransform()`; **must be recomputed if the animation range changes**, or frustum culling is wrong |
| `.copy( source, recursive )` | **`this.skeleton = source.skeleton` — the skeleton reference is SHARED, not cloned.** Sharing is intended, but it means a `clone()` does not give an independently animatable rig |

`SkinnedMesh extends Mesh`, so it also has `morphTargetInfluences` and `morphTargetDictionary`
(see §1.9).

### 1.9 Morph targets vs bones

Both animate through the same `AnimationMixer`; there is no separate morph system.

- `Mesh` (hence `SkinnedMesh`) declares `morphTargetInfluences : Array<number> | undefined` and
  `morphTargetDictionary : Object<string, number> | undefined`, both **`undefined` by default**
  until `updateMorphTargets()` runs. Do not assume they exist.
- `Mesh.updateMorphTargets()` iterates `geometry.morphAttributes`, names each target
  `morphAttribute[m].name || String(m)`, pushes `0` into `morphTargetInfluences` and sets
  `morphTargetDictionary[name] = m`.
- Bone-driven deformation is chosen by the **track name**; morph-driven by
  `.morphTargetInfluences[i]` / `.morphTargetInfluences[name]`. Both bind through
  `PropertyBinding` with `Versioning.MatrixWorldNeedsUpdate`.
- Cost: morph targets cost **vertex-shader work proportional to (vertices × active morph
  count)** and inflate the geometry buffer; bones cost a `boneMatrices` upload of
  `bones.length * 16` floats per frame plus per-vertex skinning (mat4 × vec4). Neither is
  free; prefer fewer bones for background/crowd characters and morph targets for
  face-shape changes. This reasoning is standard practice but is **not** an official
  three.js performance claim — see §4.

### 1.10 Loaders

| Loader | Import path (r186) | Animation support |
|---|---|---|
| `AnimationLoader` | `three` (core) | `three` JSON animation format. `load( url, onLoad, onProgress, onError )`; `onLoad` receives `Array<AnimationClip>`. `parse( json )` static-ish instance method. |
| `GLTFLoader` | `three/addons/loaders/GLTFLoader.js` | `gltf.animations` → `AnimationClip[]`; CUBICSPLINE; morph weights |
| `FBXLoader` | `three/addons/loaders/FBXLoader.js` | **r184 change:** "`FBXLoader` now automatically converts +Z-up models into +Y-up. Manual rotations on app level can be removed." |
| `BVHLoader` | `three/addons/loaders/BVHLoader.js` | legacy `.ani` format |
| `ColladaLoader` | `three/addons/loaders/ColladaLoader.js` | |
| `MD2Loader` / `MDDLoader` | `three/addons/loaders/` | MD2 uses `AnimationClip.CreateClipsFromMorphTargetSequences`; MDD returns `{ clip, morphTargets }` |
| `ObjectLoader` | `three` (core) | three.js JSON scene format |
| **MMD (MMDLoader / MMDFLoader / VMDLoader)** | — | **Removed.** Use `takahirox/three-mmd-loader`. |

The manual's [Animation System](https://threejs.org/manual/en/animation-system.html) page
confirms the supported set: `ObjectLoader`, `BVHLoader`, `ColladaLoader`, `FBXLoader`,
`GLTFLoader` — and warns "OBJ notably does not" support animation.

`GLTFLoader._createAnimationTracks()` (r186 source) — the exact track names it produces:

```js
const targetName = node.name ? node.name : node.uuid;   // <-- name, else uuid
// PATH_PROPERTIES = { scale:'scale', translation:'position',
//                     rotation:'quaternion', weights:'morphTargetInfluences' }
const track = new TypedKeyframeTrack(
    targetNames[ j ] + '.' + PATH_PROPERTIES[ target.path ],
    inputAccessor.array, outputArray, interpolation );
```

Track class selection: `weights` → `NumberKeyframeTrack`; `rotation` →
`QuaternionKeyframeTrack`; `translation`/`scale` → `VectorKeyframeTrack`.
`INTERPOLATION = { CUBICSPLINE: undefined, LINEAR: InterpolateLinear, STEP: InterpolateDiscrete }`.
For `CUBICSPLINE` the track is constructed with `InterpolateLinear` and then
`_createCubicSplineTrackInterpolant()` replaces `track.createInterpolant` with a factory that
divides `getValueSize()` by 3 and marks itself
`createInterpolant.isInterpolantFactoryMethodGLTFCubicSpline = true`.
**CUBICSPLINE tracks therefore report `getValueSize() * 3` as the raw stride** — the only
place in the engine that knows about this is `makeClipAdditive`, which compensates.

### 1.11 `onBeforeCompile`

Not part of the animation system and not needed for it. It exists as a
`Material` shader-injection hook (see `Material.onBeforeCompile`) and was referenced in the
r157 guide entry about `GeometricContext`. **Do not route keyframe binding through it** —
`PropertyBinding` is the supported path, and it handles `needsUpdate` /
`matrixWorldNeedsUpdate` versioning for you.

---

## 2. r177 → r186 changes that touch animation

Complete list from the Migration Guide for those ten releases (177→178 through 185→186).
Items 1–3 are the only ones with any animation consequence.

| Release | Entry | Animation impact |
|---|---|---|
| 185 → 186 | `Object3D` gained a `dispose()` method ([#34141](https://github.com/mrdoob/three.js/pull/34141)). Custom 3D object types with `dispose()` must call `super.dispose()`. | Indirect: custom `Object3D` subclasses inside a rig |
| 184 → 185 | TSL: `positionLocal` no longer applies internal vertex transforms such as `SkinnedMesh` in `material.positionNode`; use `positionGeometry`. | **WebGPU/TSL only.** Any custom skinned `positionNode` must switch. WebGL path unaffected |
| 184 → 185 | `Object3D.updateWorldMatrix()` now honours the `Object3D.matrixWorldNeedsUpdate` flag ([#33746](https://github.com/mrdoob/three.js/pull/33746)) | **Affects hand-driven rigs.** If you set `matrixAutoUpdate = false` and poke `Object.matrix` directly, you must now set `matrixWorldNeedsUpdate = true` |
| 183 → 184 | **`FBXLoader` now automatically converts +Z-up models into +Y-up** | **Direct.** Remove manual app-level rotations |
| 183 → 184 | `FileLoader.load()` and `ImageBitmapLoader.load()` have no return value; always use `onLoad` | Indirect (affects custom loader code) |
| 182 → 183 | **`Clock` deprecated. Use `Timer` instead.** | **Direct — see §2.1** |
| 178 → 179 | **The `Timer` module has been moved into the core.** No separate add-on import needed; accessible over the `THREE` namespace | **Direct — see §2.1** |
| 177 → 178 | `MultiplyBlending` / `SubtractiveBlending` now require `Material.premultipliedAlpha === true` | Not animation, but affects blending setup near animated transparency |

**Confirmed: `AnimationMixer` itself did not change at all in r177–r186.** No migration entry,
and no signature diffs in the r186 source relative to the documented r176-era API.

### 2.1 `Clock` → `Timer` (fully verified)

**Deprecation confirmed.** Guide 182 → 183: "`Clock` has been deprecated. Please use `Timer`
instead." The r186 [`src/core/Clock.js`](https://github.com/mrdoob/three.js/blob/r186/src/core/Clock.js)
source carries `@deprecated since r183` and, in the constructor,
`warn( 'Clock: This module has been deprecated. Please use THREE.Timer instead.' )`.
**`Clock` still exists and still works** — it is a warning, not a removal. Deprecation
warnings last 10 releases per the guide's own header.

**Import path: `Timer` is in CORE as of r179.** Guide 178 → 179: "The `Timer` module has been
moved into the core. There is no need to import the module as a separate add-on anymore
since it is now accessible over the `THREE` namespace."

```js
import { Timer } from 'three';        // correct in r186
// NOT: 'three/addons/misc/Timer.js'  — the examples/jsm/misc listing at ref r186 has no Timer.js
```

Verified r186 [`src/core/Timer.js`](https://github.com/mrdoob/three.js/blob/r186/src/core/Timer.js) API:

| Member | Signature / behaviour |
|---|---|
| `new THREE.Timer()` | `_startTime = performance.now()` |
| `.connect( document ) : void` | **Optional.** Enables the Page Visibility API guard. Required since r174 (see below) |
| `.disconnect() : void` | Removes the `visibilitychange` listener |
| `.update( timestamp ) : Timer` | **MUST be called once per simulation step, before any query.** `timestamp` is the rAF argument in ms; falls back to `performance.now()` |
| `.getDelta() : number` | seconds — **non-mutating**, stable within a step |
| `.getElapsed() : number` | seconds — non-mutating |
| `.getTimescale() : number` | |
| `.setTimescale( timescale ) : Timer` | returns `this`; scales the delta inside `update()` |
| `.reset() : Timer` | `_currentTime = performance.now() - _startTime` — discards the gap |
| `.dispose() : void` | calls `disconnect()` |

The r186 class doc states the design intent verbatim: "`Timer` has an `update()` method that
updates its internal state. That makes it possible to call `getDelta()` and `getElapsed()`
multiple times per simulation step without getting different values."

**This is the single biggest behavioural trap in the migration.** `Clock` self-updated inside
`getDelta()`; `Timer` does not. If you forget `timer.update()`, `getElapsed()` returns `0`
forever — this exact failure is documented on the forum
([Clock => Timer r183](https://discourse.threejs.org/t/clock-timer-r183/90704)).

Correct r186 loop:

```js
const timer = new THREE.Timer();
timer.connect( document );

renderer.setAnimationLoop( () => {
    timer.update();                       // rAF arg optional; omit or pass it
    const dt = timer.getDelta();          // seconds
    mixer.update( dt );
    renderer.render( scene, camera );
} );
```

This is verbatim the pattern in the official r186 example
[`examples/webgl_animation_skinning_blending.html`](https://github.com/mrdoob/three.js/blob/r186/examples/webgl_animation_skinning_blending.html)
(`timer = new THREE.Timer(); timer.connect( document );` … `renderer.setAnimationLoop( animate )`).

**Page Visibility / r174.** Guide 173 → 174: "`Timer` no longer uses Page Visibility API
automatically to avoid large time delta values in inactive tabs. To restore the previous
behavior, you must call the new method `timer.connect( document );`. This has been changed to
avoid side effects in the constructor."

`update()` source: if `_pageVisibilityHandler !== null && _document.hidden === true`, then
`_delta = 0` (nothing advances). A `visibilitychange` handler calls `reset()` when the document
becomes visible. **If you do not call `connect(document)`, a backgrounded tab returns and the
first frame carries the full elapsed gap.**

### 2.2 `Skeleton.calculateInverses`, `Bone.getWorldPosition/getWorldQuaternion`

All **present and unchanged** in r186. See §1.8 and §1.5 — `calculateInverses()` on
`Skeleton`; `getWorldPosition( target )`, `getWorldQuaternion( target )`,
`getWorldScale( target )`, `getWorldDirection( target )` on `Object3D`, inherited by `Bone`.
Each of the first three calls `this.updateWorldMatrix( true, false )` before reading, so they
self-heal a stale parent chain.

**Interaction with the r185 `updateWorldMatrix` change:** with `matrixAutoUpdate = false`
you must now also set `matrixWorldNeedsUpdate = true` after poking `Object.matrix`. Bones left
on `matrixAutoUpdate = true` are unaffected.

---

## 3. Fixed time step / deterministic update

### 3.1 What `mixer.update( deltaTime )` actually does (r186 source)

```js
update( deltaTime ) {
    deltaTime *= this.timeScale;
    const actions = this._actions, nActions = this._nActiveActions,
        time = this.time += deltaTime,
        timeDirection = Math.sign( deltaTime ),
        accuIndex = this._accuIndex ^= 1;
    for ( let i = 0; i !== nActions; ++ i )
        actions[ i ]._update( time, deltaTime, timeDirection, accuIndex );
    const bindings = this._bindings, nBindings = this._nActiveBindings;
    for ( let i = 0; i !== nBindings; ++ i )
        bindings[ i ].apply( accuIndex );
    return this;
}
```

Semantics, precisely:

- **Positive delta** — normal advance. `timeDirection === 1`.
- **`deltaTime === 0`** — `time` does not change, `timeDirection === 0`. Actions still run:
  `AnimationAction._update` sees `timeRunning < 0 || timeDirection === 0` and sets its local
  `deltaTime = 0`, then `PropertyMixer.apply()` still runs and still writes any property whose
  accumulated buffer differs. **So `mixer.update(0)` is a valid "re-apply current blended pose"
  call — it is how you pause without discarding state, and it is what the blending example's
  single-step feature uses.** Note `accuIndex` still flips on a zero delta, so this is a real
  frame-interleaved pass, not a no-op.
- **Negative delta** — `timeDirection === -1`, `time` moves backwards. `AnimationAction._update`
  computes `deltaTime = timeDirection * timeRunning`, and `_updateTime()` handles `LoopOnce`
  and reverse-repeat with its own branch (`if ( deltaTime >= 0 ) { ... } else { ... }`).
  Negative dt is therefore supported for playing backwards, **but** it is not a substitute for
  a clamped dt: it reverses loop bookkeeping rather than discarding a gap.
- `mixer.timeScale` multiplies the incoming dt. `timeScale = 0` freezes all actions
  (the documented pause/unpause trick per the `timeScale` JSDoc).
- Two actions with `weight === 0` still go through `_updateWeight` but are skipped for
  accumulation (`if ( weight > 0 )`).

### 3.2 `mixer.setTime( t )` for deterministic scrubbing

r186 source, verbatim:

```js
setTime( time ) {
    this.time = 0;                                    // zero the mixer
    for ( let i = 0; i < this._actions.length; i ++ )
        this._actions[ i ].time = 0;                  // zero every action
    return this.update( time );                       // then advance by exactly `time`
}
```

This is the deterministic path: it discards accumulated loop counts and per-action time, then
advances by an exact amount. The JSDoc notes the input is scaled by `timeScale`, so set
`mixer.timeScale = 1` while scrubbing. Because it is implemented as `update(time)`, it also
works as a **seek**: to jump backwards, call `setTime` with a smaller value — it does not
matter that the mixer had already advanced past it.

Use `setTime` for: timeline scrubbers, deterministic replay, golden-frame tests, network
snapshot interpolation.

### 3.3 Clamping the delta — why `Math.min( dt, 0.1 )`

Not an official three.js recommendation. It is the standard guard, and its justification is
mechanical:

- `mixer.update(dt)` is **fully time-domain-correct for arbitrary `dt`** — the interpolants
  evaluate at an absolute `clipTime`, so skipping frames does not distort the pose, it only
  makes playback move in coarser jumps. Animation is not the subsystem that breaks.
- What breaks on a spike is anything **integrating** `dt`: velocity × dt, spring/verlet
  integration, camera damping, animation-driven gameplay state. A 4-second iOS background gap
  fed straight in teleports everything.
- Practical rule: `const dt = Math.min( timer.getDelta(), 0.1 );` — cap at ~6 frames at 60 Hz.
  Animation keeps the real elapsed time if you want it to; the clamp is for your own
  integrators. A common alternative is to accumulate a fixed step
  (`while ( acc >= STEP ) { simulate( STEP ); acc -= STEP; }`) and feed the mixer
  `STEP * substeps` or the real elapsed time depending on whether you want animation to
  stay smooth or stay in sync.

**iOS Safari background-tab dt spike.** Mechanism: rAF stops firing when the tab is
backgrounded and `performance.now()` keeps advancing. On return, the first `dt` is the whole
absence. `Timer` addresses this **only if you call `connect(document)`** (§2.1) — otherwise
you must clamp or `reset()` yourself on `visibilitychange`. The Safari-specific hazards beyond
that — rAF being fully paused rather than throttled, and the OS killing the page entirely so
no rAF ever fires — are **UNVERIFIED against an official three.js or WebKit source**; treat
the Page Visibility + clamp pattern as the defensive answer and validate on device.

Note also the r185 `updateWorldMatrix` change (§2) as a second-order backgrounding hazard:
any node whose matrix you poked while the tab was hidden and that has `matrixAutoUpdate = false`
now needs an explicit `matrixWorldNeedsUpdate = true`.

---

## 4. Performance

### 4.1 What is officially documented

The three.js manual has **no page titled "Performance Tips"** at r186 — I checked
`threejs.org/manual/pages/performance-tips.html` and the manual index. There is also **no
"100 tips" page on threejs.org**; that title belongs to third-party blogs. Do not attribute
"the official Performance Tips animation bullets" to three.js — **there is no such list.**

What the official manual *does* say, all verified:

- [Optimize Lots of Objects](https://threejs.org/manual/pages/optimize-lots-of-objects.html)
  and [Optimize Lots of Objects Animated](https://threejs.org/manual/pages/optimize-lots-of-objects-animated.html):
  **merge geometry, then animate by pushing per-instance transforms/attributes** — this is
  the vertex-animation approach for huge counts. The animated page's own example
  interpolates two precomputed data sets and writes per-vertex attributes; it is about
  merged `BufferGeometry`, not `SkinnedMesh`/`AnimationMixer`.
- [How to update Things](https://threejs.org/manual/pages/how-to-update-things.html):
  "`SkinnedMesh` follows the same principles like `InstancedMesh` in context of bounding
  volumes… When calling `computeBoundingBox()` and `computeBoundingSphere()`, the class
  computes the respective bounding volumes based on the current bone transformation."
  i.e. **recompute skinned bounds after the animation range changes**, or culling breaks.
- The manual's `Animation System` page notes the system can animate bones, morph targets,
  material properties, visibility and transforms, and that weight/time scales of simultaneous
  animations are independent.

### 4.2 What the r186 source verifiably supports

These are code-verified mechanics, not folklore:

- **`PropertyMixer.apply()` skips writes when nothing changed** (double-buffered accus, compared
  before `setValue`). This is why *zero-weight* and *frozen* actions cost little on the write
  side — the cost is the interpolant `evaluate()` and `accumulate()` which still run.
- **`AnimationAction._update` returns early** when `! this.enabled` (after updating weight), so
  `action.enabled = false` is cheaper than `weight = 0`.
- **Uncached memory.** `mixer.stopAllAction()` deactivates actions but does **not** free
  bindings/interpolants. To actually release memory per the r186 docs you need
  `uncacheAction(clip, root)`, `uncacheClip(clip)`, or `uncacheRoot(root)` — and each
  requires `stop()` (or `stopAllAction()` for `uncacheRoot`) first. For a pooled/despawning
  character system this is the difference between a bounded and a growing mixer footprint.
- **`uncacheRoot`** is the one-call teardown for a whole rig; `AnimationObjectGroup.uncache( ... )`
  is the equivalent for grouped objects.
- **Bone texture.** `Skeleton.computeBoneTexture()` + `Skeleton.dispose()` — if you call
  `computeBoneTexture()` you must `dispose()` the skeleton, and `Skeleton.update()` will then
  set `boneTexture.needsUpdate = true` every frame (a texture re-upload). Only do this if the
  target needs it.
- **`AnimationObjectGroup`** shares one animation state across N objects and lets the mixer
  treat them as one root; per-object cache control happens on the group. Documented
  limitation: "A single property can either be controlled through a target group or directly,
  but not both."

### 4.3 GLTFLoader vs FBXLoader — the verified difference

- **r184: `FBXLoader` now auto-converts +Z-up to +Y-up**, so manual app-level rotations must be
  removed. This is the only loader-side behavioural change in the window.
- `GLTFLoader` produces glTF-native clip names (`nodeName.quaternion` etc.) and handles
  CUBICSPLINE; `FBXLoader` produces its own naming. If you author tracks by hand, glTF naming
  is the one the engine's own resolution path (`findNode` → `skeleton.getBoneByName` →
  child search) is best matched to.
- Verifiable cost difference: **there is none in r186 source.** Neither loader is documented as
  faster. glTF's baseline claims are from Khronos, not three.js. Do not assert a speed
  difference between the loaders from three.js documentation — you would need your own
  measurement.

### 4.4 "Animation texture / baked" approaches

**Partially verifiable.** Verified: `Skeleton.computeBoneTexture()` uploads bone matrices as a
`DataTexture` (`RGBAFormat`, `FloatType`, 4 pixels per matrix) and `Skeleton.update()` marks it
`needsUpdate`. That is the CPU-side bone-texture path. Verified absent: there is no
`AnimationTexture`, no GPU-side `AnimationMixer`, no compute-shader skinning in the r186 core
animation system. Any "bake the animation into a texture and sample it in a custom vertex
shader" scheme is **custom work, not a three.js API** — build it against the
`boneTexture` mechanism or your own `DataTexture`, and label it as bespoke.

---

## 5. Pitfalls that silently produce wrong animation

Each of these produces no error; the pose is just wrong.

1. **`AnimationUtils.arraySlice()` does not exist** (removed r157). Hand-written
   `TypedArray.slice()` instead. See §0.
2. **Mixer created before the skeleton / bind.** `PropertyBinding` resolves bone paths lazily
   on first `bind()`, and `SkinnedMesh.bind()` with no `bindMatrix` calls
   `calculateInverses()` from `matrixWorld`. If you construct the mixer, or bind the skeleton,
   before the rig is parented and its world matrices are current, you bake a wrong bind pose.
   Order: load → add to scene → `updateMatrixWorld(true)` → `mesh.bind(skeleton)` (or let
   GLTFLoader do it) → *then* `new AnimationMixer(root)`.
3. **Duplicate node names in a loaded model.** `findNode` returns the **first** match in
   `getBoneByName` / the depth-first child walk. Two bones named `Bone.001` means every track
   for `Bone.001` animates the same one. `GLTFLoader` uses `node.name ? node.name : node.uuid`,
   so **unnamed nodes are safe and named ones are not.** This is the single most common
   cause of "one limb animates, another doesn't." Detect at load: walk the tree and assert
   `Set` size equals node count.
4. **Track name reserved characters.** `[ ] . : /` are reserved by `parseTrackName`. A node
   named `arm[2]` cannot be expressed directly. Use `PropertyBinding.sanitizeNodeName()`, or
   address the node by `uuid`.
5. **Additive clips without a reference frame.** `makeClipAdditive(clip)` with the default
   `referenceFrame = 0` subtracts the pose at frame 0. If frame 0 is not the intended neutral
   pose, every additive layer is offset. Pass the correct `referenceFrame` (and `fps` matching
   your bake rate).
6. **`makeClipAdditive` matches tracks by `name` + `ValueTypeName`.** A target clip missing a
   track the reference has is silently skipped (`if ( targetTrack === undefined ) continue;`).
   No warning. Assert track-name parity between base and additive clips.
7. **`values.length` must be `times.length * valueSize`.** `getValueSize()` is computed as
   `values.length / times.length` — a mismatch yields a fractional stride, and `validate()`
   is opt-in. Constructors do not check.
8. **Rotation tracks must be quaternions, not Euler.** `QuaternionKeyframeTrack` uses
   `QuaternionLinearInterpolant` → `Quaternion.slerpFlat`. Feeding Euler triples into a
   quaternion track interpolates the 4th component as noise and does not renormalize.
   Conversely, `QuaternionKeyframeTrack.prototype.InterpolantFactoryMethodSmooth = undefined`
   — `InterpolateSmooth` on a quaternion track silently falls back to linear with a warning.
9. **Sparse keys are interpolated, not stepped.** With `times = [0, n]` and
   `InterpolateLinear`, every in-between value is a straight lerp. There is no constant-hold.
   Use `InterpolateDiscrete` for step behaviour. (glTF `STEP` maps to
   `InterpolateDiscrete`; `LINEAR` to `InterpolateLinear`.)
10. **Half-float keyframe data.** `KeyframeTrack` converts `times`/`values` to `Float32Array`
    in the constructor. If your source data was FP16 (e.g. `Uint16Array` from a
    quantized glTF), you must widen it *before* constructing the track — and half-float has
    ~3 decimal digits, so long clip durations in FP16 lose sub-frame precision. Use
    `DataUtils.fromHalfFloat` to widen. Verified: `DataUtils.toHalfFloat` / `fromHalfFloat` in
    `src/extras/DataUtils.js`; `AnimationUtils.toHalfFloat` does not exist.
11. **`Float32Array` time precision over long clips.** `times` is `Float32Array`; after
    ~100 000 seconds the representable step exceeds a frame at 60 Hz. Split long timelines.
12. **Scale tracks and additive blending.** `PropertyMixer` uses `_lerpAdditive` on the scale
    components, so additive scale is `result + delta`, not `result * delta`. Additive scale
    clips do something other than what the name suggests.
13. **`morphTargetInfluences` / `morphTargetDictionary` are `undefined` until
    `updateMorphTargets()`.** Reading `.length` on `undefined` is a throw, not a silent zero —
    but a mesh whose geometry was swapped after construction keeps the **stale** influence
    array. Call `mesh.updateMorphTargets()` after replacing geometry.
14. **CUBICSPLINE stride is 3×.** `getValueSize()` returns the triple-stride; anything of your
    own that consumes `track.values` for a CUBICSPLINE track must divide by 3 and read
    `[inTangent, vertex, outTangent]` (the engine's own layout comment).
    `makeClipAdditive` is the only engine code that accounts for this.
15. **Code and mixer writing the same node.** `PropertyMixer.apply()` compares the accumulated
    buffer against the other accu, not against the live object value. If your gameplay code
    sets `bone.quaternion` after `mixer.update(dt)`, the mixer will not "notice" and correct it
    next frame unless its own accumulated value changed — and when it *does* write, your value
    is gone. See §6.5.
16. **Skinned bounds not recomputed.** `computeBoundingSphere()` bakes the current bone pose.
    Animate outside that pose and the mesh pops out of the frustum.

---

## 6. Structuring an animation system

Engineering convention rather than three.js API. Everything below builds only on the verified
surface in §1.

### 6.1 A clip-blend layer over the mixer

`AnimationMixer` is "a player for animations on a particular object" and is described in the
manual as "a simulation of a hardware like a real mixer console" — deliberately low-level.
Put a thin layer over it. Minimum surface:

```js
class Animator {
    constructor( root, clips ) {
        this.mixer  = new THREE.AnimationMixer( root );   // created AFTER bind
        this.root   = root;
        this.clips  = new Map( clips.map( c => [ c.name, c ] ) );
        this.current = null;
        this.next    = null;
        this.state   = 'idle';
    }

    // crossfadeTo is the ONLY way this layer changes clips
    crossfadeTo( name, fadeSeconds = 0.25 ) {
        const to = this.mixer.clipAction( this.clips.get( name ) );
        if ( this.current && this.current !== to ) this.current.crossFadeTo( to, fadeSeconds );
        else to.reset().play();
        this.current = to; this.next = to;
    }

    setSpeed( s )  { this.current.timeScale = s; }
    setWeight( w ) { this.current.setEffectiveWeight( w ); }

    update( dt )   { this.mixer.update( dt ); }          // clamps done by the caller

    dispose()      { this.mixer.stopAllAction(); this.mixer.uncacheRoot( this.root ); }
}
```

Rules that keep it honest:
- `mixer.clipAction(clip)` is idempotent for the same `(clip, root)` pair — hold the returned
  `AnimationAction` in a map, never re-derive it per frame.
- Expose `crossFadeFrom` / `crossFadeTo` / `fadeIn` / `fadeOut` / `syncWith` as the only
  transition primitives. Verified above: `crossFadeTo( fadeInAction, duration )`.
- For **blend trees** (walk speed from two clips at weights `(1,0)/(0.1,0.9)/(0,1)`), use
  `setEffectiveWeight` on three simultaneously-playing actions. This is exactly what
  `webgl_animation_skinning_blending` does, and its page comment says "crossfades are
  possible with blend weights being set to (1,0,0), (0,1,0) or (0,0,1)". Each action needs
  `play()` and its own weight; the mixer accumulates them weighted-average.
- Pause with `action.paused = true` (verified property) or `mixer.timeScale = 0`. Single-step
  with `mixer.update( fixedDt )`.

### 6.2 Layers and masks — what actually exists

**There is no layer/mask API in three.js.** Verified: `AnimationObjectGroup` is the closest
thing and it is a *sharing* mechanism, not a layer. Its documented limit: "A single property
can either be controlled through a target group or directly, but not both."

The supported way to get "layers" is **separate roots + separate mixers**:

```js
const lowerBody = new THREE.AnimationMixer( hipsMesh );   // legs
const upperBody = new THREE.AnimationMixer( spineMesh );  // torso, arms, head
const additive  = new THREE.AnimationMixer( spineMesh );  // breathing / recoil
```

"Masking" a layer is therefore *structural*: give each mixer a root whose subtree is exactly
the bones it is allowed to touch, and give each clip only tracks for those bones. A track whose
`findNode` fails emits `PropertyBinding: No target node found for track: <path>` and becomes a
no-op — so a "mask" is literally the set of track names in the clip.

Rule: **one mixer per root; a node is owned by exactly one mixer.**

### 6.3 Additive layers for secondary motion

This is the idiomatic use of `AdditiveAnimationBlendMode` and it is genuinely cheap:

```js
const recoil = AnimationClip.findByName( clips, 'recoil' );   // null-check the result
AnimationUtils.makeClipAdditive( recoil, 0 );                 // ref frame 0 == neutral
const recoilAction = mixer.clipAction( recoil );
recoilAction.play();                    // plays indefinitely underneath the base clip
recoilAction.setEffectiveWeight( 0.6 ); // scales the additive contribution
```

Mechanics from `PropertyMixer`: `accumulateAdditive` accumulates into a separate `addAccu`
region seeded with the *identity* (`_setAdditiveIdentityQuaternion` /
`_setAdditiveIdentityNumeric`), then `apply()` adds it on top of the normal accumulation. For
quaternions this is slerp, so additive rotation composes correctly.

Gotchas (§5): the reference frame must be the neutral pose; track names must match the base
clip; `makeClipAdditive` mutates in place and returns the same clip.

### 6.4 1-bone vs full-skeleton cost

Per the r186 source, per frame the skeleton path costs:
- `Skeleton.update()`: one `Matrix4.multiplyMatrices` + `toArray` per bone into a
  `Float32Array(bones.length * 16)`, plus `boneTexture.needsUpdate = true` if a bone texture
  exists
- `PropertyMixer.apply()`: per active binding, a change-detect loop over `valueSize` and
  (only if changed) a `setValue` that also sets `matrixWorldNeedsUpdate = true`
- the scene-graph matrix recompute for every dirty bone, propagating up the parent chain
- per-vertex skinning in the shader (mat4 × vec4 per skin influence)

So the win from animating **one** bone instead of the whole skeleton is real but bounded:
you avoid `bones.length * 16` floats of CPU matrix work and the write-behind, but you still
pay the same vertex cost. The three scenarios where "animate just the arm" is right:
an aim-bone override on an otherwise-static character, an IK target being hand-driven while
the mixer is paused, and a prop with its own single-bone rig.

The two genuinely cheap cases are: **write directly, don't use the mixer** (set
`bone.quaternion` yourself for one joint), and **bake it into the vertex data** (§4.4).
The mixer earns its cost when you need blending, looping, and normalized-time control over a
multi-bone pose.

### 6.5 One authority per node

This is the most important structural rule, and it falls directly out of `PropertyMixer`:

```js
// WRONG — two writers to hips.quaternion in the same frame
mixer.update( dt );            // mixer writes hips.quaternion
hips.position.x += speed * dt; // gameplay writes hips.position  (different property: OK)
hips.quaternion.slerp( aimQ, k ); // gameplay writes hips.quaternion  <-- CONFLICT
```

`PropertyMixer.apply()` does not read the live object value; it compares `accu[i]` against
`accu[i+1]` and writes only on difference. So when the mixer *does* write, your value is
silently overwritten, and when it doesn't, your value persists and the animation is frozen.
Neither failure is observable at the API boundary.

Enforcement patterns, in order of preference:
1. **Structural** — separate mixers on disjoint subtrees (§6.2). If gameplay needs to move
   the hips, put gameplay motion on a parent `Object3D` and animation on the child, so the two
   write different nodes.
2. **Additive** — let the mixer own the bone; express gameplay influence as an additive clip
   or a post-mixer modulation you own, not as a direct write.
3. **Explicit handoff** — `action.paused = true` (verified) before the frame in which code
   takes over; re-enable when it gives back. Never leave both live.
4. **Convention + assertion** — a `setBone()` accessor that asserts the mixer is paused or
   that the bone has no animation track.

Note the same rule applies to `morphTargetInfluences`: the mixer and gameplay must not both
write the same index. And the interaction with r185's `updateWorldMatrix` change (§2) means
that if you write `matrix` directly on a `matrixAutoUpdate = false` node, you must also set
`matrixWorldNeedsUpdate = true`.

---

## 7. Explicitly UNVERIFIED

- Existence of an official three.js "Performance Tips" / "100 tips" page — **no such page found
  at r186.** Any bullet attributed to it is third-party.
- Relative performance of `GLTFLoader` vs `FBXLoader` — **no three.js documentation makes
  this claim.**
- iOS Safari's specific rAF/background behaviour beyond "rAF stops and `performance.now()`
  advances" — **not verified against a WebKit or three.js source.**
- `Math.min(dt, 0.1)` as three.js guidance — **not an official recommendation.** It is a
  standard integrator guard; justify it from your own integrator, not from three.js.
- "Animation texture" / GPU-skinning schemes as a three.js API — **do not exist in the r186
  core animation system.** `Skeleton.computeBoneTexture()` is verified; any scheme built on it
  is bespoke.
- `mixer.update(0)` as documented guidance for pausing — **the behaviour is verified from
  source**, but three.js does not document it as a recommended pause idiom. The
  `webgl_animation_skinning_blending` example uses `action.paused` and a single-step
  `mixer.update( sizeOfNextStep )` instead.
- Whether `AnimationAction.halt()` / `warp()` are documented as usable mid-blend — signatures
  are verified; behaviour guarantees are not documented.